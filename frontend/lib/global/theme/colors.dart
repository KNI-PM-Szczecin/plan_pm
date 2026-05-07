// System kolorów aplikacji obsługujący jasny/ciemny motyw oraz AMOLED i akcenty.
//
// ColorThemes — statyczne stałe dla obu motywów (wartości bazowe).
// AppColor — dynamiczne gettery odczytujące aktualny Brightness, amoledModeNotifier
// i accentColorNotifier, zwracając właściwy kolor w danym kontekście.
// Wywoływane przez każdy widżet używający kolorów — zamiast Theme.of(context),
// co pozwala na zmianę motywu bez przebudowy drzewa widżetów.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';

class ColorThemes {
  static const Color lightBackground = Color(0xf7f8faFF);
  static const Color lightOnBackground = Colors.black;
  static final Color lightOnBackgroundVariant = Colors.black.withAlpha(150);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Colors.black;
  static final Color lightOnSurfaceVariant = Colors.black.withAlpha(100);
  static const Color lightPrimary = Color(0xFF0884ff);
  static const Color lightOnPrimary = Colors.white;
  static final Color lightOnPrimaryVariant = Colors.black.withAlpha(180);
  static final Color lightOutline = Colors.black.withAlpha(30);
  static const int lightColorfulAlphaValue = 40;

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static final Color darkOnBackgroundVariant = Colors.white.withAlpha(150);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static final Color darkOnSurfaceVariant = Colors.white.withAlpha(100);
  static const Color darkPrimary = Color(0xFF409CFF);
  static const Color darkOnPrimary = Colors.white;
  static final Color darkOnPrimaryVariant = Colors.white.withAlpha(180);
  static final Color darkOutline = Colors.white.withAlpha(20);
  static const int darkColorfulAlphaValue = 150;
}

class AppColor {
  static Brightness _brightness = Brightness.light;

  static void update(Brightness brightness) {
    _brightness = brightness;
  }

  static Color get background {
    if (_brightness == Brightness.dark && amoledModeNotifier.value) {
      return Colors.black;
    }
    return _brightness == Brightness.light
        ? ColorThemes.lightBackground
        : ColorThemes.darkBackground;
  }

  static Color get onBackground => _brightness == Brightness.light
      ? ColorThemes.lightOnBackground
      : ColorThemes.darkOnBackground;

  static Color get onBackgroundVariant => _brightness == Brightness.light
      ? ColorThemes.lightOnBackgroundVariant
      : ColorThemes.darkOnBackgroundVariant;

  static Color get surface {
    if (_brightness == Brightness.dark && amoledModeNotifier.value) {
      return const Color(0xFF090909);
    }
    return _brightness == Brightness.light
        ? ColorThemes.lightSurface
        : ColorThemes.darkSurface;
  }

  static Color get onSurface => _brightness == Brightness.light
      ? ColorThemes.lightOnSurface
      : ColorThemes.darkOnSurface;

  static Color get onSurfaceVariant => _brightness == Brightness.light
      ? ColorThemes.lightOnSurfaceVariant
      : ColorThemes.darkOnSurfaceVariant;

  static Color get primary {
    final accent = accentColorNotifier.value;
    if (_brightness == Brightness.light) {
      switch (accent) {
        case AppAccentColor.blue:
          return ColorThemes.lightPrimary;
        case AppAccentColor.green:
          return const Color(0xFF10B981);
        case AppAccentColor.purple:
          return const Color(0xFF8B5CF6);
        case AppAccentColor.orange:
          return const Color(0xFFF59E0B);
        case AppAccentColor.red:
          return const Color(0xFFEF4444);
        case AppAccentColor.pink:
          return const Color(0xFFEC4899);
      }
    } else {
      switch (accent) {
        case AppAccentColor.blue:
          return ColorThemes.darkPrimary;
        case AppAccentColor.green:
          return const Color(0xFF34D399);
        case AppAccentColor.purple:
          return const Color(0xFFA855F7);
        case AppAccentColor.orange:
          return const Color(0xFFFBBF24);
        case AppAccentColor.red:
          return const Color(0xFFF87171);
        case AppAccentColor.pink:
          return const Color(0xFFF472B6);
      }
    }
  }

  static Color get onPrimary => _brightness == Brightness.light
      ? ColorThemes.lightOnPrimary
      : ColorThemes.darkOnPrimary;

  static Color get onPrimaryVariant => _brightness == Brightness.light
      ? ColorThemes.lightOnPrimaryVariant
      : ColorThemes.darkOnPrimaryVariant;

  static Color get outline => _brightness == Brightness.light
      ? ColorThemes.lightOutline
      : ColorThemes.darkOutline;

  static int get colorfulAlphaValue => _brightness == Brightness.light
      ? ColorThemes.lightColorfulAlphaValue
      : ColorThemes.darkColorfulAlphaValue;
}
