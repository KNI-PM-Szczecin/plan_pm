import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.title, this.action, this.child});

  final String title;
  final List<Widget>? action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColor.onBackground,
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
