class Student {
  static String? name;
  static String? surname;
  static String? course;
  static String? faculty;
  static String? degreeCourse;
  static String? specialisation;
  static int? year;
  static String? term;
  static String? degreeLevel;
  static List<String>? selectedGroups;
}

extension StudentPrinting on Student {
  String readableString() {
    return 'Student(name: ${Student.name ?? ""}, surname: ${Student.surname ?? ""}, course: ${Student.course ?? ""}, faculty: ${Student.faculty ?? ""}, degreeCourse: ${Student.degreeCourse ?? ""}, specialisation: ${Student.specialisation ?? ""}, year: ${Student.year?.toString() ?? ""}, term: ${Student.term ?? ""}, selectedGroups: ${Student.selectedGroups ?? []})';
  }
}
