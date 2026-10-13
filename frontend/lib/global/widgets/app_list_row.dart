// Wiersz listy nowego designu, kładziony w [AppGroupedSection]:
//
//   [leading]  [label]              [value] [accessory | trailing]
//              [title]
//              [subtitle]
//
// Pokrywa wszystkie wiersze z makiet: etykieta nad wartością (pole wyboru),
// tytuł z opisem, para etykieta/wartość, wiersz nawigacji z chevronem,
// link zewnętrzny ze strzałką i opcja z haczykiem.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

enum AppListRowAccessory {
  none,

  /// Przejście do kolejnego ekranu w aplikacji.
  chevron,

  /// Otwiera przeglądarkę — strzałka ↗ zamiast chevronu.
  external,

  /// Zaznaczona opcja na liście wyboru (haczyk w akcencie).
  checkmark,

  /// Pole otwierające menu wyboru (↕).
  menu,
}

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.label,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.accessory = AppListRowAccessory.none,
    this.onTap,
    this.selected,
    this.emphasized = false,
    this.titleColor,
    this.alignTop = false,
  });

  final String title;

  /// Mała etykieta NAD tytułem (np. „Wydział" nad wybraną wartością).
  final String? label;

  /// Opis POD tytułem; może mieć wiele linii.
  final String? subtitle;

  /// Wartość po prawej, w kolorze drugorzędnym (np. „Jasny", „2. rok").
  final String? value;
  final Widget? leading;

  /// Własny element po prawej — ma pierwszeństwo przed [accessory].
  final Widget? trailing;
  final AppListRowAccessory accessory;
  final VoidCallback? onTap;

  /// Ustaw, gdy wiersz jest opcją wyboru — czytniki ekranu ogłoszą stan
  /// zaznaczenia. `null` = zwykły wiersz.
  final bool? selected;

  /// Tytuł jako headline (wiersze z dłuższym opisem, np. RODO).
  final bool emphasized;

  /// Nadpisanie koloru tytułu — np. akcent dla wiersza-linku.
  final Color? titleColor;

  /// Leading przy górnej krawędzi zamiast na środku — przy wielolinijkowym opisie.
  final bool alignTop;

  Widget? _accessory() {
    final (IconData? icon, Color color) = switch (accessory) {
      AppListRowAccessory.none => (null, Colors.transparent),
      AppListRowAccessory.chevron => (
        LucideIcons.chevronRight,
        AppColor.labelTertiary,
      ),
      AppListRowAccessory.external => (
        LucideIcons.arrowUpRight,
        AppColor.labelTertiary,
      ),
      AppListRowAccessory.checkmark => (LucideIcons.check, AppColor.primary),
      AppListRowAccessory.menu => (
        LucideIcons.chevronsUpDown,
        AppColor.labelSecondary,
      ),
    };
    if (icon == null) return null;
    return Icon(
      icon,
      size: accessory == AppListRowAccessory.checkmark ? 22 : 20,
      color: color,
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        if (label != null)
          Text(
            label!,
            style: AppTextStyle.footnote.copyWith(
              color: AppColor.labelSecondary,
            ),
          ),
        Text(
          title,
          style: (emphasized ? AppTextStyle.headline : AppTextStyle.body)
              .copyWith(color: titleColor ?? AppColor.onSurface),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTextStyle.subheadline.copyWith(
              color: AppColor.labelSecondary,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing ?? _accessory();
    return Semantics(
      button: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: selected != null,
      child: AppPressable(
        feedback: AppPressFeedback.highlight,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              crossAxisAlignment: alignTop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              spacing: 12,
              children: [
                ?leading,
                // Przy parze etykieta/wartość etykieta ma naturalną szerokość,
                // a resztę dostaje wartość — długa wartość nie łamie etykiety.
                if (value == null) Expanded(child: _texts()) else _texts(),
                if (value != null)
                  Expanded(
                    child: Text(
                      value!,
                      textAlign: TextAlign.right,
                      style: AppTextStyle.body.copyWith(
                        color: AppColor.labelSecondary,
                      ),
                    ),
                  ),
                ?trailingWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
