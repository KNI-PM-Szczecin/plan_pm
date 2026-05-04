// Para przycisków FAB używana w [InputPage] i [GroupSelectionPage]:
// "Pomiń" po lewej (outlined) i przycisk potwierdzenia po prawej (filled).
// [onConfirm] == null wyłącza prawy przycisk i zmienia jego wygląd na szary.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class OnboardingActionBar extends StatelessWidget {
  const OnboardingActionBar({
    super.key,
    required this.skipLabel,
    required this.onSkip,
    required this.confirmLabel,
    this.onConfirm,
  });

  final String skipLabel;
  final VoidCallback onSkip;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColor.surface,
                  side: BorderSide(color: AppColor.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onSkip,
                child: Text(skipLabel, style: TextStyle(color: AppColor.onSurface)),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  disabledBackgroundColor: AppColor.surface,
                  foregroundColor: AppColor.onPrimary,
                  disabledForegroundColor: AppColor.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onConfirm,
                child: Text(confirmLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
