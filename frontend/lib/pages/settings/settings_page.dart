// Główna strona ustawień — rola, dane akademickie, personalizacja, feedback, debug, informacje.
// Sekcja debug pojawia się tylko po odblokowaniu easter-egga w [AboutPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/pages/external_link_page.dart';
import 'package:plan_pm/global/utils/routing.dart';
import 'package:plan_pm/global/widgets/app_grouped_page.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';
import 'package:plan_pm/pages/settings/widgets/info/group_info.dart';
import 'package:plan_pm/pages/settings/widgets/info/lecturer_info.dart';
import 'package:plan_pm/pages/settings/widgets/info/role_info.dart';
import 'package:plan_pm/pages/settings/widgets/info/student_info.dart';
import 'package:plan_pm/pages/settings/appearance_page.dart';
import 'package:plan_pm/pages/settings/language_page.dart';
import 'package:plan_pm/pages/welcome/gdpr_consent_page.dart';
import 'package:plan_pm/pages/welcome/role_selection_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:plan_pm/pages/settings/about_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/service/backend_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _debugUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadDebugState();
  }

  Future<void> _loadDebugState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _debugUnlocked = prefs.getBool(kDebugUnlockedKey) ?? false;
    });
  }

  void _open(Widget Function(BuildContext) page) {
    HapticFeedback.lightImpact();
    Navigator.push(context, appRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const iconIndent = AppGroupedSection.iconRowDividerIndent;
    return AppGroupedPage(
      title: l10n.pageTitleSettings,
      children: [
        const RoleInfo(),
        AppModeManager.current == AppMode.lecturer
            ? const LecturerInfo()
            : const StudentInfo(),
        if (AppModeManager.current == AppMode.student) const GroupInfo(),
        AppSection(
          header: l10n.personalizationHeader,
          child: AppGroupedSection(
            dividerIndent: iconIndent,
            children: [
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.paintbrush,
                  color: AppColor.systemIndigo,
                ),
                title: l10n.appearanceHeader,
                value: getThemeName(themeNotifier.value, l10n),
                accessory: AppListRowAccessory.chevron,
                onTap: () => _open((context) => const AppearancePage()),
              ),
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.globe,
                  color: AppColor.systemBlue,
                ),
                title: l10n.languageHeader,
                value: getLanguageName(localeNotifier.value, l10n),
                accessory: AppListRowAccessory.chevron,
                onTap: () => _open((context) => const LanguagePage()),
              ),
            ],
          ),
        ),
        AppSection(
          header: l10n.feedbackHeader,
          child: AppGroupedSection(
            children: [
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.messageSquare,
                  color: AppColor.systemGreen,
                ),
                title: l10n.sendFeedbackButton,
                accessory: AppListRowAccessory.chevron,
                onTap: () => _open(
                  (context) => ExternalLinkPage(
                    url: 'https://forms.gle/E8sLgZ1X49kaX5jA6',
                    icon: LucideIcons.messageSquare,
                    title: l10n.sendFeedbackButton,
                    description: l10n.feedbackPageDescription,
                    buttonLabel: l10n.sendFeedbackButton,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_debugUnlocked)
          AppSection(
            header: l10n.debugHeader,
            child: AppGroupedSection(
              children: [
                AppListRow(
                  title: l10n.debugRoleSelector,
                  accessory: AppListRowAccessory.chevron,
                  onTap: () => _open((context) => const RoleSelectionPage()),
                ),
                AppListRow(
                  title: l10n.debugClearCache,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await BackendService().clearCache();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.debugCacheCleared)),
                    );
                  },
                ),
                AppListRow(
                  title: l10n.debugShowGdpr,
                  accessory: AppListRowAccessory.chevron,
                  onTap: () => _open(
                    (context) => GdprConsentPage(onAccepted: () {}),
                  ),
                ),
                AppListRow(
                  title: l10n.debugReturnToWelcome,
                  accessory: AppListRowAccessory.chevron,
                  onTap: () => _open((context) => const WelcomePage()),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: sevenDayModeNotifier,
                  builder: (context, value, child) => AppListRow(
                    title: l10n.debugSevenDayMode,
                    trailing: Switch.adaptive(
                      value: value,
                      activeTrackColor: AppColor.primary,
                      onChanged: (_) {
                        HapticFeedback.selectionClick();
                        SevenDayModeNotifier.toggle();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        AppSection(
          header: l10n.infoSection,
          child: AppGroupedSection(
            children: [
              AppListRow(
                leading: AppIconBadge(
                  icon: LucideIcons.info,
                  color: AppColor.systemGray,
                ),
                title: l10n.aboutApp,
                accessory: AppListRowAccessory.chevron,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    appRoute((context) => const AboutPage()),
                  ).then((_) => _loadDebugState());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
