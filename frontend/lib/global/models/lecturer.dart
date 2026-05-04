// Globalna klasa statyczna przechowująca dane aktualnie zalogowanego wykładowcy.
// Pola są ładowane z SharedPreferences przy starcie apki (main.dart) i czyszczone
// przy zmianie roli. Używana przez [BackendService] do budowania zapytania o plan
// zajęć oraz przez [LecturerInfo] i [RoleInfo] w ustawieniach.
class Lecturer {
  static String? id;
  static String? name;
  static String? title;

  static String? get displayName =>
      [title, name].where((s) => s != null && s.isNotEmpty).join(' ');
}
