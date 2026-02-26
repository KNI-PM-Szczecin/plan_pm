import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_pm/global/colors.dart';

class GenericLoading extends StatelessWidget {
  const GenericLoading({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: Radius.circular(12),
          dashPattern: [10, 5],
          color: AppColor.outline,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            spacing: 5,
            children: [
              LoadingAnimationWidget.progressiveDots(
                color: AppColor.onSurfaceVariant,
                size: 48,
              ),
              Text(label, style: TextStyle(color: AppColor.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
