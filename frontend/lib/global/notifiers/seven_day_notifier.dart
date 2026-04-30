// Zarządza trybem widoku 7-dniowego w planie zajęć.
// Gdy włączony, [DaySelection] i [LecturesPage] pokazują cały tydzień zamiast
// pojedynczego dnia. Przełączany z [SettingsPage] i [RoleSelectionPage].
// SevenDayModeNotifier (statyczna klasa) obsługuje init() i toggle() z persystencją.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<bool> sevenDayModeNotifier = ValueNotifier(false);

class SevenDayModeNotifier {
  static const String key = 'seven_day_mode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    sevenDayModeNotifier.value = prefs.getBool(key) ?? false;
  }

  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    sevenDayModeNotifier.value = !sevenDayModeNotifier.value;
    await prefs.setBool(key, sevenDayModeNotifier.value);
  }
}
