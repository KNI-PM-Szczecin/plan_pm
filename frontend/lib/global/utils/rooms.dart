// Rozbijanie pola sali na pojedyncze sale.
//
// Uczelnia wpisuje kilka sal w jedno pole, rozdzielone przecinkiem w dowolnej
// pisowni („A,B", „A, B", „A , B") — tak wygląda plan, w którym zajęcia
// odbywają się w jednej z kilku sal (Nawigacja 2. rok, 11.2026). Backend
// celowo zostawia ten ciąg w całości: rozbicie na pierwszą salę gubiłoby
// pozostałe. Dlatego sale rozdziela dopiero aplikacja, tuż przed wyświetleniem.

// Lista sal bez duplikatów i pustych wpisów, w kolejności z bazy.
//
// Wpis z samym numerem („Willowa B1 14,15") dziedziczy budynek poprzedniego —
// uczelnia skraca tak sale w jednym budynku, a sama „15" nic nie mówi.
List<String> splitRooms(String? location) {
  if (location == null) return const [];
  final rooms = <String>[];
  String? building;
  for (final part in location.split(',')) {
    var room = part.trim();
    if (room.isEmpty) continue;
    final split = room.lastIndexOf(' ');
    if (split > 0) {
      building = room.substring(0, split);
    } else if (building != null) {
      room = '$building $room';
    }
    if (!rooms.contains(room)) rooms.add(room);
  }
  return rooms;
}

// Sale pogrupowane po budynku (pierwsze słowo), jedna linia na budynek:
// „Willowa – B1 117, B4 104, 107, 119", „WChrobrego – 19, 110". W obrębie
// budynku powtarzający się człon (skrzydło „B4") jest pomijany, więc zostaje
// sam numer. Jedna sala wraca bez zmian; sala bez budynku („aula") to własna
// linia. Karta pokazuje te linie zwykłym tekstem pod godziną.
List<String> groupRoomsByBuilding(List<String> rooms) {
  if (rooms.length <= 1) return rooms;
  final lines = <String>[];
  final byBuilding = <String, List<List<String>>>{};
  for (final room in rooms) {
    final tokens = room.split(' ');
    if (tokens.length == 1) {
      lines.add(room);
      continue;
    }
    byBuilding.putIfAbsent(tokens.first, () => []).add(tokens.sublist(1));
  }
  for (final entry in byBuilding.entries) {
    final parts = <String>[];
    List<String> previousPrefix = const [];
    for (final rest in entry.value) {
      final prefix = rest.sublist(0, rest.length - 1);
      final samePrefix =
          prefix.isNotEmpty &&
          prefix.length == previousPrefix.length &&
          prefix.join(' ') == previousPrefix.join(' ');
      parts.add(samePrefix ? rest.last : rest.join(' '));
      previousPrefix = prefix;
    }
    lines.add('${entry.key} – ${parts.join(', ')}');
  }
  return lines;
}

// Skrót na jeden wiersz dla widżetów ekranu głównego: pierwsza sala i „+N".
String compactRooms(String? location) {
  final rooms = splitRooms(location);
  if (rooms.isEmpty) return '';
  if (rooms.length == 1) return rooms.first;
  return '${rooms.first} +${rooms.length - 1}';
}
