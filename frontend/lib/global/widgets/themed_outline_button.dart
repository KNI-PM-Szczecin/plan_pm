import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';

class ThemedOutlineButton extends StatelessWidget {
  const ThemedOutlineButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(icon),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColor.surface,
        foregroundColor: AppColor.onSurface,
        side: BorderSide(color: AppColor.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
