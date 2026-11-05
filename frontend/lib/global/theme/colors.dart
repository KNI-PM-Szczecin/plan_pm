// System kolorów aplikacji obsługujący jasny/ciemny motyw i akcenty.
//
// ColorThemes — statyczne stałe dla obu motywów (wartości bazowe).
// AppColor — dynamiczne gettery odczytujące aktualny Brightness i accentColorNotifier,
// zwracając właściwy kolor w danym kontekście.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';

class ColorThemes {
  // Color() to ARGB — alfa idzie PIERWSZA. Było `0xf7f8faFF` (zapis RGBA), czyli
  // tło o kryciu 97%: przy przejściu poprzedni ekran prześwitywał przez nowy,
  // a po animacji znikał i kolor całego ekranu skakał (flicker od 1.0).
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightOnBackground = Colors.black;
  static final Color lightOnBackgroundVariant = Colors.black.withAlpha(150);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Colors.black;
  static final Color lightOnSurfaceVariant = Colors.black.withAlpha(100);
  static const Color lightPrimary = Color(0xFF0884ff);
  static const Color lightOnPrimary = Colors.white;
  static final Color lightOutline = Colors.black.withAlpha(30);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static final Color darkOnBackgroundVariant = Colors.white.withAlpha(150);
  static const Color darkSurface = Color(0xFF1C1C1C);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static final Color darkOnSurfaceVariant = Colors.white.withAlpha(100);
  static const Color darkPrimary = Color(0xFF409CFF);
  static const Color darkOnPrimary = Colors.white;
  static final Color darkOutline = Colors.white.withAlpha(10);

  static const Color success = Color(0xFF30D158);
  static const Color destructive = Color(0xFFFF453A);
}

class AppColor {
  static Brightness _brightness = Brightness.light;

  static void update(Brightness brightness) {
    _brightness = brightness;
  }

  static Color get background => _brightness == Brightness.light
      ? ColorThemes.lightBackground
      : ColorThemes.darkBackground;

  static Color get onBackground => _brightness == Brightness.light
      ? ColorThemes.lightOnBackground
      : ColorThemes.darkOnBackground;

  static Color get onBackgroundVariant => _brightness == Brightness.light
      ? ColorThemes.lightOnBackgroundVariant
      : ColorThemes.darkOnBackgroundVariant;

  static Color get surface => _brightness == Brightness.light
      ? ColorThemes.lightSurface
      : ColorThemes.darkSurface;

  static Color get surfaceElevated => _brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : ColorThemes.darkSurfaceElevated;

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

  static Color get success => ColorThemes.success;

  static Color get destructive => ColorThemes.destructive;

  static Color get outline => _brightness == Brightness.light
      ? ColorThemes.lightOutline
      : ColorThemes.darkOutline;

  // Role z design systemu (iOS 27 Flat). Półprzezroczyste — leżą na
  // dowolnym tle i same dopasowują się do niego.

  /// Tekst pomocniczy: podtytuły, opisy pod nagłówkiem.
  static Color get labelSecondary => _brightness == Brightness.light
      ? const Color(0x993C3C43)
      : const Color(0xB2EBEBF5);

  /// Tylko placeholdery i nieaktywny tekst — poniżej 4.5:1, nie na treść.
  static Color get labelTertiary => _brightness == Brightness.light
      ? const Color(0x4D3C3C43)
      : const Color(0x4DEBEBF5);

  /// Tło nieaktywnej kontrolki, pola wyszukiwania.
  static Color get fillTertiary => _brightness == Brightness.light
      ? const Color(0x1F767680)
      : const Color(0x3D767680);

  /// Stałe kolory systemowe — na kafelki ikon, które mają wyglądać tak samo
  /// niezależnie od wybranego akcentu (np. rola student / wykładowca).
  static Color get systemBlue => _brightness == Brightness.light
      ? const Color(0xFF0088FF)
      : const Color(0xFF0091FF);

  static Color get systemIndigo => _brightness == Brightness.light
      ? const Color(0xFF6155F5)
      : const Color(0xFF6D7CFF);

  /// Najlżejsze wypełnienie — wciśnięty wiersz listy, duże tła.
  static Color get fillQuaternary => _brightness == Brightness.light
      ? const Color(0x14747480)
      : const Color(0x2E767680);

  /// Tło strony z listami grupowanymi (Ustawienia, O aplikacji, menu boczne).
  static Color get groupedBackground => _brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF000000);

  /// Karta sekcji na [groupedBackground] i tło okienek dialogowych.
  static Color get groupedSurface => _brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF1C1C1E);

  /// Przyciemnienie strony pod okienkiem dialogowym i menu bocznym.
  static Color get overlay => _brightness == Brightness.light
      ? const Color(0x33000000)
      : const Color(0x7A000000);

  static Color get systemGreen => _brightness == Brightness.light
      ? const Color(0xFF34C759)
      : const Color(0xFF30D158);

  static Color get systemOrange => _brightness == Brightness.light
      ? const Color(0xFFFF8D28)
      : const Color(0xFFFF9230);

  static Color get systemYellow => _brightness == Brightness.light
      ? const Color(0xFFFFCC00)
      : const Color(0xFFFFD600);

  static Color get systemRed =>_brightness == Brightness.light
      ? const Color(0xFFFF383C)
      : const Color(0xFFFF4245);

  static Color get systemPurple => _brightness == Brightness.light
      ? const Color(0xFFCB30E0)
      : const Color(0xFFDB34F2);

  static Color get systemGray => const Color(0xFF8E8E93);

  /// Cienka linia: separator wierszy, obrys kafelka.
  static Color get separator => _brightness == Brightness.light
      ? const Color(0x1F000000)
      : const Color(0x2BFFFFFF);

  static Color rectorHoursBackground(Brightness brightness) => 
      brightness == Brightness.dark 
          ? Color.lerp(Colors.grey.shade900, Colors.black, 0.1)! 
          : Colors.grey.shade700;

  static Color get rectorHoursBadge => Colors.white.withValues(alpha: 0.1);
}
