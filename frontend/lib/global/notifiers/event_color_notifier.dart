// Zarządza stylem kolorowania kart zajęć (current, pastel, vibrant, monochrome).
// Odczytywany przez widżet [Lecture] i [DaySelection] do doboru koloru karty.
// Używany w [AppearancePage] do zmiany stylu oraz w [main.dart] do inicjalizacji.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EventColorStyle { current, pastel, vibrant, monochrome }

class EventColorStyleNotifier extends ValueNotifier<EventColorStyle> {
  static const String _key = 'event_color_style';

  EventColorStyleNotifier() : super(EventColorStyle.current);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    value = EventColorStyle.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => EventColorStyle.current,
    );
  }

  Future<void> setEventStyle(EventColorStyle style) async {
    value = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.name);
  }
}

late final EventColorStyleNotifier eventColorStyleNotifier;
