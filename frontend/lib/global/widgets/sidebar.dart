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

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(
          right: BorderSide(color: AppColor.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
                child: Text(
                  'Plan PM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppTextSize.title1,
                    fontWeight: FontWeight.w700,
                    color: AppColor.onBackground,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Nav items ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _SidebarNavItem(
                      icon: LucideIcons.activity,
                      label: l10n.pePageTitle,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onPeTap();
                      },
                    ),
                    _SidebarNavItem(
                      icon: LucideIcons.creditCard,
                      label: l10n.studentIdPageTitle,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onStudentIdTap();
                      },
                    ),
                    _SidebarNavItem(
                      icon: LucideIcons.landmark,
                      label: l10n.virtualUniversityPageTitle,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onVirtualUniversityTap();
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── What's new + Settings ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _SidebarNavItem(
                  icon: LucideIcons.sparkles,
                  label: l10n.whatsNewTitle,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onWhatsNewTap();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _SidebarNavItem(
                  icon: LucideIcons.settings,
                  label: l10n.pageTitleSettings,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSettingsTap();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.onBackgroundVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: AppColor.primary.withAlpha(30),
          highlightColor: AppColor.primary.withAlpha(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppTextSize.subhead,
                      fontWeight: FontWeight.w500,
                      color: color,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
