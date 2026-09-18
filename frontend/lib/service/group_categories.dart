// Klasyfikacja grup zajęciowych na sekcje ekranu wyboru grup.
//
// Kod grupy wygląda tak: "P0A04/WIET/2024/2025 ZS" — kod / pula / rocznik.
// Z kodu czytamy typ zajęć, z puli to, czy grupa należy do rocznika studenta,
// czy do wydziałowej puli przedmiotów obieralnych.
//
// Po co osobna klasyfikacja: ekran grupował po PIERWSZEJ LITERZE kodu i pozwalał
// zaznaczyć jedną pozycję w kategorii. Grupa projektowa ("P01/LTZ") i wszystkie
// obieralne ("P0A04/WIET") lądowały więc w jednym worku "Inne" i student wybierał
// jedną z kilkunastu — stąd trzy zgłoszenia o niepełnym planie. Obieralnych ma się
// kilka naraz, więc ta jedna sekcja jest wielokrotnego wyboru.

/// Typ sekcji na ekranie wyboru grup.
enum GroupKind { auditorium, classes, labs, project, simulator, elective, other }

// Obieralne: "P" + numer puli + litera typu (+ numer), np. P0A04, P0L04A, P0C03B.
// Zwykła grupa projektowa ("P01") nie ma litery po numerze, więc tu nie wpada.
final RegExp _electiveCode = RegExp(r'^P\d+[A-Za-z]', caseSensitive: false);

// Wydziałowa pula przedmiotów obieralnych ("WIET", "WIET MGR").
const String _electivePool = "WIET";

/// Jedna grupa gotowa do wyświetlenia.
class GroupEntry {
  const GroupEntry({
    required this.full,
    required this.code,
    required this.pool,
    required this.kind,
  });

  /// Pełna wartość z bazy — to ona trafia do `Student.selectedGroups`.
  final String full;

  /// Część przed pierwszym "/" — etykieta przycisku, np. "P0A04".
  final String code;

  /// Druga część, czyli pula/tok, np. "LTZ" albo "WIET".
  final String pool;

  final GroupKind kind;
}

/// Sekcja ekranu: grupy jednego typu plus informacja, czy wolno zaznaczyć kilka.
class GroupSection {
  const GroupSection({
    required this.kind,
    required this.entries,
    required this.multiSelect,
  });

  final GroupKind kind;
  final List<GroupEntry> entries;

  /// true tylko dla przedmiotów obieralnych — w pozostałych sekcjach student
  /// należy dokładnie do jednej grupy.
  final bool multiSelect;
}

String groupCodeOf(String group) => group.split("/").first.trim();

String groupPoolOf(String group) {
  final parts = group.split("/");
  return parts.length > 1 ? parts[1].trim() : "";
}

/// Typ zajęć wyczytany z kodu grupy.
GroupKind classifyGroup(String group) {
  final code = groupCodeOf(group);
  final pool = groupPoolOf(group);

  if (_electiveCode.hasMatch(code) ||
      pool.toUpperCase().startsWith(_electivePool)) {
    return GroupKind.elective;
  }

  final letters = RegExp(r'^[A-Za-z]+').firstMatch(code)?.group(0) ?? "";
  return switch (letters.toUpperCase()) {
    "A" => GroupKind.auditorium,
    "C" => GroupKind.classes,
    "L" => GroupKind.labs,
    "P" => GroupKind.project,
    "SYM" => GroupKind.simulator,
    _ => GroupKind.other,
  };
}

// Kolejność sekcji na ekranie. Obieralne na końcu, bo są opcjonalne i najdłuższe.
const List<GroupKind> _order = [
  GroupKind.auditorium,
  GroupKind.classes,
  GroupKind.labs,
  GroupKind.project,
  GroupKind.simulator,
  GroupKind.other,
  GroupKind.elective,
];

/// Sortuje grupy po numerze w kodzie, a przy remisie alfabetycznie.
int compareGroupCodes(String a, String b) {
  final numberA = RegExp(r'\d+').firstMatch(a);
  final numberB = RegExp(r'\d+').firstMatch(b);
  if (numberA != null && numberB != null) {
    final byNumber = int.parse(numberA.group(0)!)
        .compareTo(int.parse(numberB.group(0)!));
    if (byNumber != 0) return byNumber;
  }
  return a.compareTo(b);
}

/// Buduje sekcje ekranu z surowej listy grup zwróconej przez backend.
List<GroupSection> buildGroupSections(List<String> groups) {
  final Map<GroupKind, List<GroupEntry>> byKind = {};
  for (final group in groups) {
    if (group.trim().isEmpty) continue;
    final kind = classifyGroup(group);
    byKind.putIfAbsent(kind, () => []).add(
      GroupEntry(
        full: group,
        code: groupCodeOf(group),
        pool: groupPoolOf(group),
        kind: kind,
      ),
    );
  }

  final sections = <GroupSection>[];
  for (final kind in _order) {
    final entries = byKind[kind];
    if (entries == null || entries.isEmpty) continue;
    entries.sort((a, b) => compareGroupCodes(a.code, b.code));
    sections.add(
      GroupSection(
        kind: kind,
        entries: entries,
        multiSelect: kind == GroupKind.elective,
      ),
    );
  }
  return sections;
}
