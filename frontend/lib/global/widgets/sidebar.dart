// Boczny panel nawigacyjny aplikacji (drawer).
// Zawiera skróty do PE, legitymacji, wirtualnego dziekanatu, ustawień
// i "Co nowego". Montowany jako drawer głównego Scaffold w [main.dart].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(
            right: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(18)
                  : Colors.black.withAlpha(18),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color.lerp(AppColor.primary, Colors.white, 0.25)!,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset('assets/logo_light.png'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Plan PM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.onBackground,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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

              // ── Divider + What's new + Settings ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(18),
                  thickness: 1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
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
                      fontSize: 15,
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
