// Logika startowa aplikacji — odczytuje SharedPreferences i decyduje który widok pokazać.
// Wywoływana raz przy starcie przez [App], przed zdjęciem splash screena.
import 'package:flutter/widgets.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/pages/welcome/role_selection_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> appInitialization() async {
  AppLogger.i("[APP-INIT] Start");
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey("skip_welcome")) {
    return const WelcomePage();
  }

  await AppModeManager.loadFromPrefs();

  if (AppModeManager.current == AppMode.lecturer) {
    Lecturer.id = prefs.getString('lecturer_id');
    Lecturer.name = prefs.getString('lecturer_name');
    Lecturer.title = prefs.getString('lecturer_title');

    if (Lecturer.id == null || Lecturer.name == null) {
      return const RoleSelectionPage();
    }

    sevenDayModeNotifier.value = true;

    try {
      await CacheService().syncLectures();
    } catch (error) {
      AppLogger.e("[APP-INIT] syncLectures error", error);
    }
    try {
      await CacheService().syncNews();
    } catch (error) {
      AppLogger.e("[APP-INIT] syncNews error", error);
    }

    return const MyHomePage(title: "Strona główna");
  }

  // Ścieżka studenta
  Student.course = prefs.getString("course");
  Student.degreeCourse = prefs.getString("degree_course");
  Student.faculty = prefs.getString("faculty");
  final String? spec = prefs.getString("specialisation");
  Student.specialisation = (spec != null && spec.isNotEmpty) ? spec : null;
  Student.year = prefs.getInt("year");

  final String? rawStudyMode =
      prefs.getString("study_mode") ?? prefs.getString("term");
  Student.studyMode = switch (rawStudyMode) {
    "S" || "Stacjonarne" => StudyMode.stationary,
    "N" || "Niestacjonarne" => StudyMode.notStationary,
    _ => null,
  };
  Student.degreeLevel = prefs.getString("degree_level");
  Student.selectedGroups = prefs.getStringList("groups");

  final bool allFieldsArePresent =
      Student.course != null &&
      Student.degreeCourse != null &&
      Student.faculty != null &&
      Student.year != null &&
      Student.studyMode != null &&
      Student.selectedGroups != null;

  if (!allFieldsArePresent) {
    return const InputPage();
  }

  try {
    await CacheService().syncLectures();
    await CacheService().syncNews();
  } catch (error) {
    AppLogger.e("[APP-INIT] Caching error", error);
  }

  return const MyHomePage(title: "Strona główna");
}
