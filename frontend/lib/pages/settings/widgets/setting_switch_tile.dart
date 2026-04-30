// Wiersz z przełącznikiem używany w ustawieniach — etykieta po lewej, Switch po prawej.
// Opcjonalny [subtitle] wyświetla szary opis pod etykietą.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class SettingSwitchTile extends StatelessWidget {
  const SettingSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColor.primary,
      title: Text(label, style: TextStyle(color: AppColor.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: AppColor.onSurfaceVariant, fontSize: 13))
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
