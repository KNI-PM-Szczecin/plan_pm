// Sekcja ekranu ustawień: nagłówek (z opcjonalną akcją lub dopiskiem po
// prawej), treść — zwykle [AppGroupedSection] — i stopka z objaśnieniem.
//
// Nagłówek na iOS to szare WERSALIKI, na Androidzie zwykłe zdanie w kolorze
// akcentu — tak jak w systemowych ustawieniach obu platform.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.child,
    this.header,
    this.headerNote,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final Widget child;
  final String? header;

  /// Dopisek po prawej od nagłówka, bez akcji (np. „Wybrano: 2").
  final String? headerNote;

  /// Akcja tekstowa po prawej od nagłówka (np. „Edytuj", „Zmień grupy").
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? footer;

  /// Pionowy odstęp między kolejnymi sekcjami na ekranie.
  static const double spacing = 28;

  @override
  Widget build(BuildContext context) {
    final hasHeaderRow = header != null || actionLabel != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (hasHeaderRow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: header == null
                      ? const SizedBox.shrink()
                      : Text(
                          isApplePlatform ? header!.toUpperCase() : header!,
                          style: isApplePlatform
                              ? AppTextStyle.footnote.copyWith(
                                  color: AppColor.labelSecondary,
                                )
                              : AppTextStyle.footnoteEmphasized.copyWith(
                                  color: AppColor.primary,
                                ),
                        ),
                ),
                if (headerNote != null)
                  Text(
                    headerNote!,
                    style: AppTextStyle.footnote.copyWith(
                      color: AppColor.labelSecondary,
                    ),
                  ),
                if (actionLabel != null)
                  AppPressable(
                    onTap: onAction,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Semantics(
                      button: true,
                      child: Text(
                        actionLabel!,
                        style: AppTextStyle.subheadline.copyWith(
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        child,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              footer!,
              style: AppTextStyle.footnote.copyWith(
                color: AppColor.labelSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
