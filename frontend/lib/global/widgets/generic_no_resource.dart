import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';

class GenericNoResource extends StatelessWidget {
  const GenericNoResource({
    super.key,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        dashPattern: [10, 5],
        radius: Radius.circular(12),
        color: AppColor.outline,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
        ),

        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 5,
            children: [
              Icon(icon, size: 32, color: AppColor.onSurfaceVariant),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColor.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
