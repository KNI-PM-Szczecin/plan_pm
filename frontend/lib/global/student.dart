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
  static String? degreeCourse;
  static String? specialisation;
  static int? year;
  static StudyMode? studyMode;
  static String? degreeLevel;
  static List<String>? selectedGroups;
}

extension StudentPrinting on Student {
  String readableString() {
    return 'Student(course: ${Student.course ?? ""}, faculty: ${Student.faculty ?? ""}, degreeCourse: ${Student.degreeCourse ?? ""}, specialisation: ${Student.specialisation ?? ""}, year: ${Student.year?.toString() ?? ""}, studyMode: ${Student.studyMode?.displayName ?? ""}, selectedGroups: ${Student.selectedGroups ?? []})';
  }
}
