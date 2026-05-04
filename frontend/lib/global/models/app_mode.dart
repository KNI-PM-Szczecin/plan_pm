// Określa aktywny tryb aplikacji: student lub wykładowca.
// AppModeManager przechowuje bieżący tryb jako pole statyczne i persystuje go
// w SharedPreferences (klucz 'app_mode'). Tryb jest ładowany przy starcie
// w main.dart i zmieniany w [RoleSelectionPage] podczas onboardingu.
// Odczytywany przez [BackendService] (inne zapytanie do Supabase),
// [CacheService] (merge zajęć dla wykładowcy), [LecturesPage] i [Lecture]
// (różne zachowanie UI), oraz [RoleInfo] w ustawieniach.
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
