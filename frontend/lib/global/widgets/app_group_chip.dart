// Pastylka z kodem grupy (np. „L02", „P0A04"). Jeden wygląd w dwóch miejscach:
//   - podsumowanie wybranych grup w ustawieniach — bez [onTap], tylko etykieta,
//   - ekran wyboru grup — z [onTap]; [selected] wypełnia ją kolorem akcentu.
// Feedback dotyku jak w reszcie komponentów `App*` ([AppPressable]).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

class AppGroupChip extends StatelessWidget {
  const AppGroupChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;

  /// `null` = pastylka tylko do odczytu.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      style: AppTextStyle.subheadlineEmphasized.copyWith(
        color: selected ? AppColor.onPrimary : AppColor.onSurface,
      ),
    );
    final background = selected ? AppColor.primary : AppColor.fillTertiary;

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: ShapeDecoration(
          color: background,
          shape: const StadiumBorder(),
        ),
        child: text,
      );
    }

    // Klikalna wersja jest wyższa (cel dotyku) i ma zaokrąglone rogi zamiast
    // pastylki — jak przyciski grup sprzed redesignu. Przy narzuconej
    // szerokości (siatka w wyborze grup) etykieta jest wyśrodkowana, a za
    // długi kod zmniejsza się zamiast ucinać.
    return Semantics(
      button: true,
      selected: selected,
      child: AppPressable(
        onTap: onTap,
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: FittedBox(fit: BoxFit.scaleDown, child: text),
          ),
        ),
      ),
    );
  }
}
