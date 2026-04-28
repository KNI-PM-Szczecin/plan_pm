import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { student, lecturer }

class AppModeManager {
  static AppMode current = AppMode.student;

  static Future<void> setMode(AppMode mode) async {
    current = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode.name);
  }

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_mode');
    current = raw == 'lecturer' ? AppMode.lecturer : AppMode.student;
  }
}
