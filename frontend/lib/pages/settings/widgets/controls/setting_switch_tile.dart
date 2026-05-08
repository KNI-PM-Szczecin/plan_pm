// Wiersz z przełącznikiem używany w ustawieniach — etykieta po lewej, Switch po prawej.
// Opcjonalny [subtitle] wyświetla szary opis pod etykietą.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';

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
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: AppTextSize.body, color: AppColor.onBackground)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppColor.onSurfaceVariant,
                fontSize: AppTextSize.footnote,
              ),
            )
          : null,
      trailing: defaultTargetPlatform == TargetPlatform.iOS
          ? CupertinoSwitch(
              activeTrackColor: AppColor.primary,
              value: value,
              onChanged: onChanged,
            )
          : Switch(
              activeTrackColor: AppColor.primary,
              value: value,
              onChanged: onChanged,
            ),
    );
  }
}
