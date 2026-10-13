// Strona "O aplikacji" — logo KNI, wersja, opis, twórcy i link do repozytorium.
// Easter egg: 7 tapnięć w wersję odblokowuje sekcję debug w [SettingsPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_grouped_page.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plan_pm/global/utils/logger.dart';

const String kDebugUnlockedKey = 'debug_unlocked';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = "unknown";
  int _tapCount = 0;
  bool _debugUnlocked = false;

  static const String _debugUnlockedKey = kDebugUnlockedKey;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _loadDebugState();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = "${info.version}+${info.buildNumber}";
      });
    } catch (e) {
      AppLogger.w("[ABOUT] Nie udało się odczytać wersji aplikacji", e);
    }
  }

  Future<void> _loadDebugState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _debugUnlocked = prefs.getBool(_debugUnlockedKey) ?? false;
    });
  }

  SnackBar _styledSnackBar({required Widget icon, required String text}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: AppColor.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      elevation: 0,
      content: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColor.onSurface, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onVersionTap() async {
    if (_debugUnlocked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tapCount++;
    });
    if (_tapCount >= 7) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_debugUnlockedKey, true);
      if (!mounted) return;
      setState(() {
        _debugUnlocked = true;
      });
      HapticFeedback.heavyImpact();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            _styledSnackBar(
              icon: Icon(Icons.check_circle, color: AppColor.success, size: 22),
              text: l10n.debugModeUnlocked,
            ),
          );
      }
    } else if (_tapCount >= 3) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            _styledSnackBar(
              icon: Icon(
                Icons.mouse,
                color: AppColor.onSurface.withValues(alpha: 0.7),
                size: 22,
              ),
              text: l10n.debugTapsRemaining(7 - _tapCount),
            ),
          );
      }
    }
  }

  Future<void> _disableDebug() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugUnlockedKey, false);
    if (!mounted) return;
    setState(() {
      _debugUnlocked = false;
      _tapCount = 0;
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        _styledSnackBar(
          icon: Icon(
            Icons.do_not_disturb_on,
            color: AppColor.destructive,
            size: 22,
          ),
          text: l10n.debugModeDisabled,
        ),
      );
  }

  Future<void> _launchRepo() async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse('https://github.com/KNI-PM-Szczecin/plan_pm');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenRepo)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppGroupedPage(
      title: l10n.aboutApp,
      children: [
        Column(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/kni_logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Plan PM",
              style: AppTextStyle.title1Emphasized.copyWith(
                color: AppColor.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            // Easter egg: 7 tapnięć w wersję odblokowuje debug w Ustawieniach.
            AppPressable(
              onTap: _onVersionTap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _version.isNotEmpty ? "${l10n.version} $_version" : l10n.version,
                style: AppTextStyle.subheadline.copyWith(
                  color: AppColor.labelSecondary,
                ),
              ),
            ),
            if (_debugUnlocked) ...[
              const SizedBox(height: 8),
              AppPressable(
                onTap: _disableDebug,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.debugModeDisable,
                  style: AppTextStyle.footnote.copyWith(
                    color: AppColor.systemRed,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.appDescription,
                textAlign: TextAlign.center,
                style: AppTextStyle.subheadline.copyWith(
                  color: AppColor.labelSecondary,
                ),
              ),
            ),
          ],
        ),
        AppSection(
          header: l10n.createdBy,
          child: AppGroupedSection(
            children: [
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.code,
                  color: AppColor.systemBlue,
                ),
                // W tłumaczeniu jest złamanie linii pod stary, wyśrodkowany układ.
                title: l10n.kniName.replaceAll("\n", " "),
              ),
            ],
          ),
        ),
        AppSection(
          header: l10n.openSourceHeader,
          footer: l10n.openSourceInfo,
          child: AppGroupedSection(
            children: [
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.gitFork,
                  color: Colors.black,
                ),
                title: l10n.githubRepo,
                titleColor: AppColor.primary,
                accessory: AppListRowAccessory.external,
                onTap: _launchRepo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
