// Globalna klasa statyczna przechowująca dane aktualnie zalogowanego studenta
// oraz enum StudyMode opisujący tryb studiów (stacjonarne / niestacjonarne).
//
// Pola Student są ładowane z SharedPreferences przy starcie apki (main.dart)
// i czyszczone przy zmianie roli lub wylogowaniu. Używane przez [BackendService]
// do budowania zapytania o plan zajęć, przez [LecturesPage] i [DaySelection]
// do nawigacji po tygodniach, oraz przez widżety ustawień ([StudentInfo], [GroupInfo]).
//
// StudyMode.programType ("S" / "N") jest używany jako filtr w zapytaniu Supabase.
// StudyModeExtension.fromProgramType() deserializuje wartość zapisaną w SharedPreferences.
enum StudyMode { stationary, notStationary }

extension StudyModeExtension on StudyMode {
  String get displayName => switch (this) {
    StudyMode.stationary => "Stacjonarne",
    StudyMode.notStationary => "Niestacjonarne",
  };

  String get programType => switch (this) {
    StudyMode.stationary => "S",
    StudyMode.notStationary => "N",
  };

  static StudyMode fromProgramType(String type) => switch (type) {
    "S" => StudyMode.stationary,
    _ => StudyMode.notStationary,
  };
}

class Student {
  static String? course;
  static String? faculty; // Wydział
  static String? degreeCourse; // Kierunek
  static String? specialisation; // Specjalizacja
  static int? year;
  static StudyMode? studyMode; // Tryb studiów - Stacjonarne/Niestacjonarne
  static String? degreeLevel;
  static List<String>? selectedGroups;
}

// Zamienia obiekt na string, do lepszego debugowania
extension StudentPrinting on Student {
  String readableString() {
    return 'Student(course: ${Student.course ?? ""}, faculty: ${Student.faculty ?? ""}, degreeCourse: ${Student.degreeCourse ?? ""}, specialisation: ${Student.specialisation ?? ""}, year: ${Student.year?.toString() ?? ""}, studyMode: ${Student.studyMode?.displayName ?? ""}, selectedGroups: ${Student.selectedGroups ?? []})';
  }
}
