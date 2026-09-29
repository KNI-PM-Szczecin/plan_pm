// Strona ustawień wyglądu — motyw, kolor akcentu, styl kolorów zajęć.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_grouped_page.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
import 'package:plan_pm/global/widgets/app_radio_indicator.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return AppGroupedPage(
      title: l10n.appearanceHeader,
      children: [
        AppSection(
          header: l10n.themeHeader,
          footer: l10n.themeSystemHint,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) => _Card(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  for (final (mode, label, asset) in [
                    (
                      ThemeMode.light,
                      l10n.themeLight,
                      'assets/theme_light.png',
                    ),
                    (ThemeMode.dark, l10n.themeDark, 'assets/theme_dark.png'),
                    (
                      ThemeMode.system,
                      l10n.themeSystem,
                      'assets/theme_mixed.png',
                    ),
                  ])
                    Expanded(
                      child: _ThemeOption(
                        label: label,
                        asset: asset,
                        selected: currentMode == mode,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          themeNotifier.setTheme(mode);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        AppSection(
          header: l10n.accentColorTitle,
          child: ValueListenableBuilder<AppAccentColor>(
            valueListenable: accentColorNotifier,
            builder: (context, currentColor, _) => _Card(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final color in AppAccentColor.values)
                    _AccentOption(
                      color: getAccentColorValue(color, brightness),
                      selected: currentColor == color,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        accentColorNotifier.setAccentColor(color);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        AppSection(
          header: l10n.eventStyleTitle,
          child: ValueListenableBuilder<EventColorStyle>(
            valueListenable: eventColorStyleNotifier,
            builder: (context, currentStyle, _) => AppGroupedSection(
              children: [
                for (final style in EventColorStyle.values)
                  AppListRow(
                    leading: _StyleSwatches(colors: _swatchesFor(style)),
                    title: getEventStyleName(style, l10n),
                    selected: style == currentStyle,
                    accessory: style == currentStyle
                        ? AppListRowAccessory.checkmark
                        : AppListRowAccessory.none,
                    onTap: () => eventColorStyleNotifier.setEventStyle(style),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Trzy pierwsze kolory kart zajęć w danym stylu — z tych samych list, z których
  /// rysuje je karta, więc podgląd nie rozjedzie się z planem.
  static List<Color> _swatchesFor(EventColorStyle style) {
    final List<LinearGradient>? gradients = switch (style) {
      EventColorStyle.current => defaultGradients,
      EventColorStyle.pastel => pastelGradients,
      EventColorStyle.vibrant => vibrantGradients,
      EventColorStyle.monochrome => null,
    };
    if (gradients == null) return List.filled(3, AppColor.primary);
    return [
      for (var i = 0; i < 3; i++) gradients[i % gradients.length].colors.first,
    ];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: AppColor.groupedSurface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppGroupedSection.radius),
        ),
      ),
      child: child,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: AppPressable(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          spacing: 10,
          children: [
            AspectRatio(
              aspectRatio: 0.72,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(3),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      width: 2,
                      color: selected ? AppColor.primary : AppColor.separator,
                    ),
                  ),
                ),
                child: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            Text(
              label,
              style: AppTextStyle.subheadline.copyWith(
                color: AppColor.onSurface,
              ),
            ),
            AppRadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _AccentOption extends StatelessWidget {
  const _AccentOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppPressable(
        onTap: onTap,
        shape: const CircleBorder(),
        // Obwódka odsunięta o 3 pt od koła, jak outline-offset w makiecie.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: selected ? color : Colors.transparent,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? const Icon(LucideIcons.check, color: Colors.white, size: 22)
                : null,
          ),
        ),
      ),
    );
  }
}

class _StyleSwatches extends StatelessWidget {
  const _StyleSwatches({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        for (final color in colors)
          Container(
            width: 8,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
