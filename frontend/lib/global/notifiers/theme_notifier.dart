// Zarządza motywem aplikacji (jasny / ciemny / systemowy).
// Wartość jest persystowana w SharedPreferences i ładowana przy starcie (main.dart).
// Używany w [AppearancePage] do zmiany motywu oraz w [main.dart] do inicjalizacji
// i przekazania do MaterialApp.themeMode.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const String _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'light':
        value = ThemeMode.light;
        break;
      case 'dark':
        value = ThemeMode.dark;
        break;
      default:
        value = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_key, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_key, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_key, 'system');
        break;
    }
  }
}

late final ThemeNotifier themeNotifier;
