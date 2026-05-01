// Czyste funkcje mapujące enumeracje ustawień wyglądu na wartości UI.
// Używane przez [AppearancePage] — wydzielone by odchudzić klasę widgetu.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

String getThemeName(ThemeMode mode, AppLocalizations l10n) {
  if (mode == ThemeMode.light) return l10n.themeLight;
  if (mode == ThemeMode.dark) return l10n.themeDark;
  return l10n.themeSystem;
}

String getEventStyleName(EventColorStyle style, AppLocalizations l10n) {
  switch (style) {
    case EventColorStyle.current: return l10n.eventStyleCurrent;
    case EventColorStyle.pastel: return l10n.eventStylePastel;
    case EventColorStyle.vibrant: return l10n.eventStyleVibrant;
    case EventColorStyle.monochrome: return l10n.eventStyleMonochrome;
  }
}

// Zwraca wartość koloru akcentu dla danego motywu — jasny/ciemny wariant osobno
// bo Material3 wymaga różnych odcieni dla dobrego kontrastu.
Color getAccentColorValue(AppAccentColor color, Brightness brightness) {
  if (brightness == Brightness.light) {
    switch (color) {
      case AppAccentColor.blue:   return ColorThemes.lightPrimary;
      case AppAccentColor.green:  return const Color(0xFF10B981);
      case AppAccentColor.purple: return const Color(0xFF8B5CF6);
      case AppAccentColor.orange: return const Color(0xFFF59E0B);
      case AppAccentColor.red:    return const Color(0xFFEF4444);
      case AppAccentColor.pink:   return const Color(0xFFEC4899);
    }
  } else {
    switch (color) {
      case AppAccentColor.blue:   return ColorThemes.darkPrimary;
      case AppAccentColor.green:  return const Color(0xFF34D399);
      case AppAccentColor.purple: return const Color(0xFFA855F7);
      case AppAccentColor.orange: return const Color(0xFFFBBF24);
      case AppAccentColor.red:    return const Color(0xFFF87171);
      case AppAccentColor.pink:   return const Color(0xFFF472B6);
    }
  }
}
