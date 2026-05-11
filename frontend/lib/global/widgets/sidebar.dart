// Boczny panel nawigacyjny aplikacji.
// Zawiera skróty do PE, legitymacji, wirtualnego dziekanatu, ustawień i "Co nowego".
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.onPeTap,
    required this.onStudentIdTap,
    required this.onVirtualUniversityTap,
    required this.onSettingsTap,
    required this.onWhatsNewTap,
  });

  final VoidCallback onPeTap;
  final VoidCallback onStudentIdTap;
  final VoidCallback onVirtualUniversityTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onWhatsNewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Material(
        color: AppColor.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/logo_light.png',
                          color: brightness == Brightness.light
                              ? Colors.white
                              : null,
                          colorBlendMode: brightness == Brightness.light
                              ? BlendMode.srcIn
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Plan PM',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: AppTextSize.title2,
                          fontWeight: FontWeight.w700,
                          color: AppColor.onBackground,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main nav section ─────────────────────────────────────
                _SidebarSection(
                  children: [
                    _SidebarItem(
                      icon: LucideIcons.activity,
                      label: l10n.pePageTitle,
                      onTap: () { HapticFeedback.lightImpact(); onPeTap(); },
                    ),
                    _SidebarDivider(),
                    _SidebarItem(
                      icon: LucideIcons.creditCard,
                      label: l10n.studentIdPageTitle,
                      onTap: () { HapticFeedback.lightImpact(); onStudentIdTap(); },
                    ),
                    _SidebarDivider(),
                    _SidebarItem(
                      icon: LucideIcons.landmark,
                      label: l10n.virtualUniversityPageTitle,
                      onTap: () { HapticFeedback.lightImpact(); onVirtualUniversityTap(); },
                    ),
                  ],
                ),

                const Spacer(),

                // ── Footer section ───────────────────────────────────────
                _SidebarSection(
                  children: [
                    _SidebarItem(
                      icon: LucideIcons.sparkles,
                      label: l10n.whatsNewTitle,
                      onTap: () { HapticFeedback.lightImpact(); onWhatsNewTap(); },
                    ),
                    _SidebarDivider(),
                    _SidebarItem(
                      icon: LucideIcons.settings,
                      label: l10n.pageTitleSettings,
                      onTap: () { HapticFeedback.lightImpact(); onSettingsTap(); },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: AppColor.outline,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: AppColor.onBackgroundVariant, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w400,
                    color: AppColor.onBackground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
