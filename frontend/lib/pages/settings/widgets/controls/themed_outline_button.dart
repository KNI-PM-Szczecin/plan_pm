// Przycisk tekstowy dopasowany do motywu — ikona + etykieta.
// Używany w kartach informacyjnych jako przycisk akcji (edytuj, zmień grupy).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

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
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      style: TextButton.styleFrom(
        foregroundColor: AppColor.primary,
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
