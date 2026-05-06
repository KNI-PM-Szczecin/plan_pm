// Zarządza kolorem akcentu aplikacji (niebieski, zielony, fioletowy, itp.).
// AppAccentColor jest odczytywany przez AppColor.primary w colors.dart,
// co sprawia że zmiana koloru jest natychmiastowa w całej aplikacji.
// Używany w [AppearancePage] do wyboru koloru oraz w [main.dart] do inicjalizacji.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccentColor { blue, green, purple, orange, red, pink }

class AccentColorNotifier extends ValueNotifier<AppAccentColor> {
  static const String _key = 'accent_color';

  AccentColorNotifier() : super(AppAccentColor.blue);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    value = AppAccentColor.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppAccentColor.blue,
    );
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, color.name);
  }
}

late final AccentColorNotifier accentColorNotifier;
