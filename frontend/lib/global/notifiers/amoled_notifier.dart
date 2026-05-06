// Zarządza trybem AMOLED — gdy włączony, tło w ciemnym motywie jest czysto czarne
// zamiast ciemnoszarego, co oszczędza baterię na ekranach OLED.
// Odczytywany przez AppColor.background i AppColor.surface w colors.dart.
// Używany w [AppearancePage] do przełączania oraz w [main.dart] do inicjalizacji.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmoledModeNotifier extends ValueNotifier<bool> {
  static const String _key = 'amoled_mode';

  AmoledModeNotifier() : super(false);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_key) ?? false;
  }

  Future<void> setAmoledMode(bool amoled) async {
    value = amoled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, amoled);
  }
}

late final AmoledModeNotifier amoledModeNotifier;
