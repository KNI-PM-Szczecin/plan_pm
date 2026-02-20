import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return Column(
          children: [
            _ThemeOption(
              title: l10n.themeLight,
              isSelected: currentMode == ThemeMode.light,
              onTap: () => _selectTheme(ThemeMode.light),
              isFirst: true,
            ),
            Divider(height: 1, color: AppColor.outline, indent: 12, endIndent: 12),
            _ThemeOption(
              title: l10n.themeDark,
              isSelected: currentMode == ThemeMode.dark,
              onTap: () => _selectTheme(ThemeMode.dark),
            ),
            Divider(height: 1, color: AppColor.outline, indent: 12, endIndent: 12),
            _ThemeOption(
              title: l10n.themeSystem,
              isSelected: currentMode == ThemeMode.system,
              onTap: () => _selectTheme(ThemeMode.system),
              isLast: true,
            ),
          ],
        );
      },
    );
  }

  void _selectTheme(ThemeMode mode) {
    HapticFeedback.selectionClick();
    themeNotifier.setTheme(mode);
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: AppColor.onSurface),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: AppColor.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
