// Rozszerzenia na String — formatowanie wielkości liter.
// toCapitalized: pierwsza litera wielka, reszta mała ("INFORMATYKA" → "Informatyka").
// toTitleCase: każde słowo z wielką literą ("jan kowalski" → "Jan Kowalski").
// Używane w [DaySelection] do formatowania nazw miesięcy z l10n (np. "Kwiecień").
extension StringCasingExtension on String {
  String get toCapitalized =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String get toTitleCase => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized).join(' ');
}

// Rozszerzenia na DateTime — nawigacja po dniach tygodnia.
// next(day): zwraca najbliższą przyszłą datę dla podanego dnia tygodnia
// (np. DateTime.monday), lub dziś jeśli dzisiaj jest ten dzień.
// Używane w testach jednostkowych [models_and_utils_test.dart].
extension DateTimeExtension on DateTime {
  DateTime next(int day) {
    return add(Duration(days: (day - weekday) % DateTime.daysPerWeek));
  }
}
