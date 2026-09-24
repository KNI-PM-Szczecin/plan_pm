// Para przycisków FAB używana w [InputPage] i [GroupSelectionPage]:
// "Pomiń" po lewej (outlined) i przycisk potwierdzenia po prawej (filled).
// [onConfirm] == null wyłącza prawy przycisk i zmienia jego wygląd na szary.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class OnboardingActionBar extends StatelessWidget {
  /// Wysokość samych przycisków.
  static const double barHeight = 50;

  /// Ile miejsca musi zarezerwować na dole przewijana treść strony, żeby jej
  /// ostatni element dało się przewinąć **nad** pasek. Pasek pływa nad body,
  /// więc bez tego zapasu ostatni rząd zostaje fizycznie pod przyciskami i
  /// nie da się go kliknąć — widać to na szerokich/niskich ekranach
  /// (rozłożony foldable, tablet), gdzie treść kończy się dokładnie na
  /// wysokości paska.
  static double reservedSpace(BuildContext context) =>
      barHeight +
      kFloatingActionButtonMargin * 2 +
      MediaQuery.paddingOf(context).bottom;

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
              height: barHeight,
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
              height: barHeight,
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
