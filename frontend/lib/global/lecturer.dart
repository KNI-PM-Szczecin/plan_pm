class Lecturer {
  static String? id;
  static String? name;
  static String? title;

  static String? get displayName =>
      [title, name].where((s) => s != null && s.isNotEmpty).join(' ');
}
