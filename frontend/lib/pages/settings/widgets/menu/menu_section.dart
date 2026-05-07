// Sekcja menu z tytułem, opcjonalnymi przyciskami akcji i zawartością w obramowanym kontenerze.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.title, this.action, this.child});

  final String title;
  final List<Widget>? action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: AppColor.onBackgroundVariant,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            ...?action,
          ],
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.outline),
          ),
          child: child,
        ),
      ],
    );
  }
}
