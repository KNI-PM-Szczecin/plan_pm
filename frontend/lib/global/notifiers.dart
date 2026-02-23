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

class LocaleNotifier extends ValueNotifier<Locale?> {
  static const String _key = 'locale';

  LocaleNotifier() : super(null);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'pl':
        value = const Locale('pl');
        break;
      case 'en':
        value = const Locale('en');
        break;
      case 'uk':
        value = const Locale('uk');
        break;
      default:
        value = null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_key, 'system');
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

late final LocaleNotifier localeNotifier;
