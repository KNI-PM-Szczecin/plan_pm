// Wiersz szczegółu zajęcia w rozwijanej sekcji karty [Lecture] — kolorowa ikona, etykieta i wartość.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/typography.dart';

class DescriptionItem extends StatelessWidget {
  const DescriptionItem({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.content,
    required this.textColor,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String content;

  /// Kolor tekstu karty — biały albo ciemny na pastelu.
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        spacing: 10,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyle.footnote.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  content,
                  style: AppTextStyle.subheadlineEmphasized.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
