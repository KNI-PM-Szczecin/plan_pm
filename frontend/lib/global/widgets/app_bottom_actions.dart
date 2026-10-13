// Przyklejony dół ekranu: cienka linia nad, jeden lub dwa przyciski obok
// siebie i opcjonalny przypis pod nimi (np. „Możesz cofnąć zgodę…").
// Wstawiaj jako ostatnie dziecko kolumny ekranu, pod przewijaną treścią.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';

class AppBottomActions extends StatelessWidget {
  const AppBottomActions({
    super.key,
    required this.primary,
    this.secondary,
    this.note,
    this.showDivider = true,
  });

  /// Zwykle [AppButton] w wariancie filled.
  final Widget primary;

  /// Drugi przycisk po lewej (np. „Pomiń" w wariancie gray).
  final Widget? secondary;
  final String? note;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: AppColor.separator))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          secondary == null ? 24 : 16,
          12,
          secondary == null ? 24 : 16,
          // Na telefonach z paskiem gestów przyciski siedzą tuż nad nim.
          bottomInset > 0 ? bottomInset : 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            if (secondary == null)
              primary
            else
              Row(
                spacing: 12,
                children: [
                  Expanded(child: secondary!),
                  Expanded(child: primary),
                ],
              ),
            if (note != null)
              Text(
                note!,
                textAlign: TextAlign.center,
                style: AppTextStyle.footnote.copyWith(
                  color: AppColor.labelSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
