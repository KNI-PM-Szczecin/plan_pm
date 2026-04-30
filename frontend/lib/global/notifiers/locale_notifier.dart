// Zarządza językiem interfejsu (pl / en / uk / null = systemowy).
// Wartość jest persystowana w SharedPreferences i ładowana przy starcie (main.dart).
// Używany w [LanguagePage] do zmiany języka oraz w [main.dart] do przekazania
// do MaterialApp.locale.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
