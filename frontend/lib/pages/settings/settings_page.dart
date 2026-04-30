import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/pages/external_link_page.dart';
import 'package:plan_pm/global/widgets/standard_app_bar.dart';
import 'package:plan_pm/pages/settings/widgets/setting_switch_tile.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/pages/settings/widgets/group_info.dart';
import 'package:plan_pm/pages/settings/widgets/lecturer_info.dart';
import 'package:plan_pm/pages/settings/widgets/menu_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu_section.dart';
import 'package:plan_pm/pages/settings/widgets/role_info.dart';
import 'package:plan_pm/pages/settings/widgets/student_info.dart';
import 'package:plan_pm/pages/settings/appearance_page.dart';
import 'package:plan_pm/pages/settings/language_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: StandardAppBar(title: l10n.pageTitleSettings),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const RoleInfo(),
                  AppModeManager.current == AppMode.lecturer
                      ? const LecturerInfo()
                      : const StudentInfo(),
                  if (AppModeManager.current == AppMode.student) const GroupInfo(),
                  MenuSection(
                    title: l10n.personalizationHeader,
                    child: Column(
                      children: [
                        MenuButton(
                          title: l10n.appearanceHeader,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppearancePage(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColor.outline),
                        MenuButton(
                          title: l10n.languageHeader,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguagePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  MenuSection(
                    title: l10n.feedbackHeader,
                    child: MenuButton(
                      title: l10n.sendFeedbackButton,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExternalLinkPage(
                              url: 'https://forms.gle/E8sLgZ1X49kaX5jA6',
                              icon: LucideIcons.messageSquare,
                              title: l10n.sendFeedbackButton,
                              description: l10n.feedbackPageDescription,
                              buttonLabel: l10n.sendFeedbackButton,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_debugUnlocked)
                    MenuSection(
                      title: l10n.debugHeader,
                      child: Column(
                        children: [
                          MenuButton(
                            title: l10n.debugRoleSelector,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RoleSelectionPage(),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: AppColor.outline),
                          MenuButton(
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
                          Divider(height: 1, color: AppColor.outline),
                          MenuButton(
                            title: l10n.debugReturnToWelcome,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WelcomePage(),
                                ),
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: sevenDayModeNotifier,
                            builder: (context, value, child) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: SettingSwitchTile(
                                label: l10n.debugSevenDayMode,
                                value: value,
                                onChanged: (_) => SevenDayModeNotifier.toggle(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  MenuSection(
                    title: l10n.infoSection,
                    child: MenuButton(
                      title: l10n.aboutApp,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        ).then((_) => _loadDebugState());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
