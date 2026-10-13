// Wspólny przycisk nowego designu (iOS 27 Flat): pigułka, płaskie tło.
// Feedback dotyku zależy od platformy — patrz [AppPressable].
//
// Wygląd dobiera [AppButtonVariant], wysokość [AppButtonSize]. Kolor akcentu
// idzie za [AppColor.primary], więc szanuje wybrany w ustawieniach akcent.
// `onPressed == null` wyłącza przycisk, `isLoading` pokazuje spinner i blokuje tap.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

enum AppButtonVariant {
  /// Główna akcja ekranu — pełny akcent, biały tekst. Jedna na ekran.
  filled,

  /// Akcja drugorzędna — przygaszony akcent w tle, tekst w akcencie.
  tinted,

  /// Neutralna — szare tło, tekst w kolorze etykiet (np. „Pomiń" obok głównej).
  gray,

  /// Szare tło, tekst w akcencie — akcja w treści (np. „Spróbuj ponownie").
  secondary,

  /// Sam tekst w akcencie, bez tła (np. „Pomiń" pod przyciskiem w okienku).
  plain,
}

enum AppButtonSize {
  /// 50 pt, headline — przyciski na dole ekranu i w okienkach.
  large,

  /// 34 pt, subheadline semibold — przyciski w treści, w kartach.
  small,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Ikona przed etykietą.
  final IconData? icon;

  /// Ikona za etykietą — np. strzałka ↗ przy linku zewnętrznym.
  final IconData? trailingIcon;
  final bool isLoading;

  /// `true` = pełna szerokość rodzica, `false` = szerokość treści.
  final bool expand;

  /// Lekka wibracja przy tapnięciu — domyślnie jak w reszcie aplikacji.
  final bool haptic;

  bool get _enabled => onPressed != null && !isLoading;

  (Color background, Color foreground) _colors() {
    final accent = AppColor.primary;
    if (!_enabled && !isLoading) {
      return variant == AppButtonVariant.plain
          ? (Colors.transparent, AppColor.labelTertiary)
          : (AppColor.fillTertiary, AppColor.labelTertiary);
    }
    return switch (variant) {
      AppButtonVariant.filled => (accent, Colors.white),
      AppButtonVariant.tinted => (accent.withValues(alpha: 0.15), accent),
      AppButtonVariant.gray => (AppColor.fillTertiary, AppColor.onBackground),
      AppButtonVariant.secondary => (AppColor.fillTertiary, accent),
      AppButtonVariant.plain => (Colors.transparent, accent),
    };
  }

  TextStyle _textStyle() {
    if (size == AppButtonSize.small) return AppTextStyle.subheadlineEmphasized;
    // Przycisk tekstowy w okienku jest lżejszy od głównego (body vs headline).
    return variant == AppButtonVariant.plain
        ? AppTextStyle.body
        : AppTextStyle.headline;
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors();
    final isLarge = size == AppButtonSize.large;
    final iconSize = isLarge ? 20.0 : 16.0;

    final content = isLoading
        ? (isApplePlatform
              ? CupertinoActivityIndicator(color: foreground)
              : SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: foreground,
                  ),
                ))
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (icon != null) Icon(icon, size: iconSize, color: foreground),
              Flexible(
                child: Text(
                  label,
                  style: _textStyle().copyWith(color: foreground),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: iconSize, color: foreground),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: AppPressable(
        color: background,
        shape: const StadiumBorder(),
        onTap: _enabled
            ? () {
                if (haptic) HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: Container(
          width: expand ? double.infinity : null,
          // minHeight, nie height — przy dużym Dynamic Type tekst ma rosnąć,
          // a nie być ucinany.
          constraints: BoxConstraints(
            minHeight: isLarge
                ? (variant == AppButtonVariant.plain ? 44 : 50)
                : 34,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 20 : 14,
            vertical: isLarge ? 12 : 7,
          ),
          alignment: expand ? Alignment.center : null,
          child: content,
        ),
      ),
    );
  }
}
