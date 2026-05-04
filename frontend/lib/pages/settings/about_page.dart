// Strona "O aplikacji" — wersja, logo KNI, link do repozytorium.
// Easter egg: 7 tapnięć w wersję odblokowuje sekcję debug w [SettingsPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/standard_app_bar.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.debugModeUnlocked)),
        );
      }
    } else if (_tapCount >= 3) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.debugTapsRemaining(7 - _tapCount))),
          );
      }
    }
  }

  Future<void> _launchRepo() async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse('https://github.com/KNI-PM-Szczecin/plan_pm');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenRepo)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: StandardAppBar(title: l10n.aboutApp),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          // Logo KNI
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/kni_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // App Name and Version
                          Text(
                            "Plan PM",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColor.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _onVersionTap,
                            child: Text(
                              _version.isNotEmpty
                                  ? "${l10n.version} $_version"
                                  : l10n.version,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.onBackgroundVariant,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              l10n.appDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.onBackgroundVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          Icon(
                            LucideIcons.code,
                            color: AppColor.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.createdBy,
                            style: TextStyle(
                              color: AppColor.onBackgroundVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.kniName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColor.onBackground,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColor.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColor.outline),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.heart,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.openSourceInfo,
                                      style: TextStyle(
                                        color: AppColor.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _launchRepo();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      foregroundColor: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: Icon(LucideIcons.github, size: 20),
                                    label: Text(
                                      l10n.githubRepo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
