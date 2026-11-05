import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/utils/rooms.dart';

void main() {
  group('splitRooms', () {
    test('returns an empty list for a missing room', () {
      expect(splitRooms(null), isEmpty);
      expect(splitRooms(''), isEmpty);
      expect(splitRooms(' , '), isEmpty);
    });

    test('keeps a single room untouched', () {
      expect(splitRooms('WChrobrego 55'), ['WChrobrego 55']);
    });

    test('splits rooms joined without a space (Nawigacja, 2nd year)', () {
      expect(
        splitRooms(
          'Willowa B1 117,Willowa B4 104,Willowa B4 107,Willowa B4 119',
        ),
        [
          'Willowa B1 117',
          'Willowa B4 104',
          'Willowa B4 107',
          'Willowa B4 119',
        ],
      );
    });

    test('splits rooms joined with spaces around the comma', () {
      expect(splitRooms('WChrobrego 19 , WChrobrego 110'), [
        'WChrobrego 19',
        'WChrobrego 110',
      ]);
      expect(splitRooms('WChrobrego 19, WChrobrego 110'), [
        'WChrobrego 19',
        'WChrobrego 110',
      ]);
    });

    test('gives a bare room number the building of the previous room', () {
      expect(splitRooms('Willowa B1 14,15'), [
        'Willowa B1 14',
        'Willowa B1 15',
      ]);
      expect(splitRooms('WChrobrego 311/313,WChrobrego 326/327'), [
        'WChrobrego 311/313',
        'WChrobrego 326/327',
      ]);
    });

    test('keeps a bare room without any building as is', () {
      expect(splitRooms('aula,CIRM'), ['aula', 'CIRM']);
    });

    test('drops duplicates while keeping the order', () {
      expect(splitRooms('B4 104,B4 107,B4 104'), ['B4 104', 'B4 107']);
    });
  });

  group('groupRoomsByBuilding', () {
    test('returns a single room untouched', () {
      expect(groupRoomsByBuilding(['WChrobrego 55']), ['WChrobrego 55']);
      expect(groupRoomsByBuilding([]), isEmpty);
    });

    test('joins rooms of one building and elides a repeated wing', () {
      expect(
        groupRoomsByBuilding([
          'Willowa B1 117',
          'Willowa B4 104',
          'Willowa B4 107',
          'Willowa B4 119',
        ]),
        ['Willowa – B1 117, B4 104, 107, 119'],
      );
      expect(groupRoomsByBuilding(['WChrobrego 19', 'WChrobrego 110']), [
        'WChrobrego – 19, 110',
      ]);
    });

    test('gives every building its own line, in order of appearance', () {
      expect(
        groupRoomsByBuilding([
          'WChrobrego 19',
          'Willowa B1 14',
          'WChrobrego 110',
          'Willowa B1 15',
        ]),
        ['WChrobrego – 19, 110', 'Willowa – B1 14, 15'],
      );
    });

    test('keeps a room without a building as its own line', () {
      expect(groupRoomsByBuilding(['aula', 'WChrobrego 19', 'CIRM']), [
        'aula',
        'CIRM',
        'WChrobrego – 19',
      ]);
    });
  });

  group('compactRooms', () {
    test('returns an empty string for a missing room', () {
      expect(compactRooms(null), '');
    });

    test('returns a single room as is', () {
      expect(compactRooms('WChrobrego 55'), 'WChrobrego 55');
    });

    test('shows the first room and the count of the others', () {
      expect(
        compactRooms('Willowa B1 117,Willowa B4 104,Willowa B4 107'),
        'Willowa B1 117 +2',
      );
    });
  });
}
