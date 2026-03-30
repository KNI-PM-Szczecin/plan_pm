import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class CustomSidebar extends StatelessWidget {
  const CustomSidebar({
    super.key,
    required this.currentIndex,
    required this.onChange,
    required this.onSettingsTap,
  });

  final int currentIndex;
  final Function(int newIndex) onChange;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _SidebarItem(icon: LucideIcons.home, label: l10n.pageTitleHome),
      _SidebarItem(icon: LucideIcons.calendar, label: l10n.pageTitleLectures),
      _SidebarItem(icon: LucideIcons.newspaper, label: l10n.pageTitleNews),
    ];

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(
            right: BorderSide(
              color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(18),
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
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.graduationCap,
                        color: Colors.white,
                        size: 18,
                      ),
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
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isActive = currentIndex == index;
                    return _SidebarNavItem(
                      icon: item.icon,
                      label: item.label,
                      isActive: isActive,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChange(index);
                        Navigator.of(context).pop();
                      },
                    );
                  }),
                ),
              ),

              const Spacer(),

              // ── Divider + Settings ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(18),
                  thickness: 1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _SidebarNavItem(
                  icon: LucideIcons.settings,
                  label: l10n.pageTitleSettings,
                  isActive: false,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
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
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColor.primary;
    final inactiveColor = AppColor.onBackgroundVariant;
    final color = isActive ? activeColor : inactiveColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: activeColor.withAlpha(30),
          highlightColor: activeColor.withAlpha(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withAlpha(22) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
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
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
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

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}
