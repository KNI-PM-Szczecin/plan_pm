import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';

class DescriptionItem extends StatelessWidget {
  const DescriptionItem({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.content,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String content;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          spacing: 10,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(AppColor.colorfulAlphaValue),
              child: Icon(icon, color: AppColor.onPrimaryVariant),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(color: AppColor.onBackgroundVariant),
                  ),
                  Text(
                    content,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
