import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/extensions.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/service/backend_service.dart';

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

Map<String, dynamic> baseLectureJson({
  String id = "abc123",
  String subject = "Matematyka",
  String startTime = "2026-03-23T08:00:00",
  String endTime = "2026-03-23T09:30:00",
  String group = "GR1",
  List<Map<String, dynamic>> teachers = const [],
  Map<String, dynamic>? rooms,
  String? notes,
}) =>
    {
      "id": id,
      "subject": subject,
      "startTime": startTime,
      "endTime": endTime,
      "group": group,
      "teachersclasses": teachers,
      "rooms": rooms,
      "notes": notes,
    };

Map<String, dynamic> teacherEntry(String title, String fullName) => {
      "teachers": {"title": title, "fullName": fullName},
    };

Map<String, dynamic> roomEntry(String buildingName, String roomName) => {
      "name": roomName,
      "building": {"name": buildingName},
    };

// ────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────

void main() {
  // ── StringCasingExtension ──────────────────────────────────

  group('StringCasingExtension', () {
    group('toCapitalized', () {
      test('małe litery → pierwsza wielka', () {
        expect('hello'.toCapitalized, 'Hello');
      });

      test('wszystkie wielkie → tylko pierwsza wielka', () {
        expect('HELLO'.toCapitalized, 'Hello');
      });

      test('mieszane → tylko pierwsza wielka', () {
        expect('hElLo'.toCapitalized, 'Hello');
      });

      test('jeden znak', () {
        expect('a'.toCapitalized, 'A');
        expect('A'.toCapitalized, 'A');
      });

      test('pusty string → pusty string', () {
        expect(''.toCapitalized, '');
      });

      test('nie dotyka kolejnych słów', () {
        expect('hello world'.toCapitalized, 'Hello world');
      });
    });

    group('toTitleCase', () {
      test('jedno słowo', () {
        expect('hello'.toTitleCase, 'Hello');
      });

      test('wiele słów', () {
        expect('hello world'.toTitleCase, 'Hello World');
      });

      test('wielkie litery → tytuł', () {
        expect('HELLO WORLD'.toTitleCase, 'Hello World');
      });

      test('wiele spacji między słowami → jedna', () {
        expect('hello  world'.toTitleCase, 'Hello World');
        expect('hello   world'.toTitleCase, 'Hello World');
      });

      test('pusty string → pusty string', () {
        expect(''.toTitleCase, '');
      });
    });
  });

  // ── DateTimeExtension.next ─────────────────────────────────

  group('DateTimeExtension.next', () {
    // Poniedziałek 23 marca 2026
    final monday = DateTime(2026, 3, 23);
    final friday = DateTime(2026, 3, 27);
    final sunday = DateTime(2026, 3, 29);

    test('poniedziałek → następny piątek (+4)', () {
      expect(monday.next(DateTime.friday), DateTime(2026, 3, 27));
    });

    test('piątek → następny poniedziałek (+3)', () {
      final result = friday.next(DateTime.monday);
      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 30);
      expect(result.weekday, DateTime.monday);
    });

    test('niedziela → następny piątek (+5)', () {
      final result = sunday.next(DateTime.friday);
      expect(result.year, 2026);
      expect(result.month, 4);
      expect(result.day, 3);
      expect(result.weekday, DateTime.friday);
    });

    test('ten sam dzień → zwraca ten sam dzień (0 dni)', () {
      expect(monday.next(DateTime.monday), monday);
      expect(friday.next(DateTime.friday), friday);
    });
  });

  // ── StudyModeExtension ─────────────────────────────────────

  group('StudyModeExtension', () {
    group('displayName', () {
      test('stationary → Stacjonarne', () {
        expect(StudyMode.stationary.displayName, 'Stacjonarne');
      });

      test('notStationary → Niestacjonarne', () {
        expect(StudyMode.notStationary.displayName, 'Niestacjonarne');
      });
    });

    group('programType', () {
      test('stationary → S', () {
        expect(StudyMode.stationary.programType, 'S');
      });

      test('notStationary → N', () {
        expect(StudyMode.notStationary.programType, 'N');
      });
    });

    group('fromProgramType', () {
      test('S → stationary', () {
        expect(StudyModeExtension.fromProgramType('S'), StudyMode.stationary);
      });

      test('N → notStationary', () {
        expect(StudyModeExtension.fromProgramType('N'), StudyMode.notStationary);
      });

      test('nieznana wartość → notStationary', () {
        expect(StudyModeExtension.fromProgramType('X'), StudyMode.notStationary);
        expect(StudyModeExtension.fromProgramType(''), StudyMode.notStationary);
      });
    });

    test('roundtrip: programType → fromProgramType', () {
      for (final mode in StudyMode.values) {
        expect(StudyModeExtension.fromProgramType(mode.programType), mode);
      }
    });
  });

  // ── LectureModel.fromJson ──────────────────────────────────

  group('LectureModel.fromJson', () {
    group('wykładowcy', () {
      test('jeden wykładowca z tytułem', () {
        final model = LectureModel.fromJson(baseLectureJson(
          teachers: [teacherEntry('dr', 'Jan Kowalski')],
        ));
        expect(model.professor, 'dr Jan Kowalski');
      });

      test('wielu wykładowców → rozdzieleni przecinkiem', () {
        final model = LectureModel.fromJson(baseLectureJson(
          teachers: [
            teacherEntry('dr', 'Jan Kowalski'),
            teacherEntry('prof.', 'Anna Nowak'),
          ],
        ));
        expect(model.professor, 'dr Jan Kowalski, prof. Anna Nowak');
      });

      test('brak wykładowców → professor null', () {
        final model = LectureModel.fromJson(baseLectureJson(teachers: []));
        expect(model.professor, isNull);
      });

      test('wykładowca z null teachers → filtrowany', () {
        final model = LectureModel.fromJson(baseLectureJson(
          teachers: [
            {"teachers": null},
            teacherEntry('dr', 'Jan Kowalski'),
          ],
        ));
        expect(model.professor, 'dr Jan Kowalski');
      });

      test('wykładowca z pustym tytułem i imieniem → filtrowany', () {
        final model = LectureModel.fromJson(baseLectureJson(
          teachers: [
            {"teachers": {"title": null, "fullName": null}},
            teacherEntry('dr', 'Anna Nowak'),
          ],
        ));
        expect(model.professor, 'dr Anna Nowak');
      });

      test('wykładowca bez tytułu (null) → samo imię', () {
        final model = LectureModel.fromJson(baseLectureJson(
          teachers: [
            {"teachers": {"title": null, "fullName": "Jan Kowalski"}},
          ],
        ));
        expect(model.professor, 'Jan Kowalski');
      });
    });

    group('sala i budynek', () {
      test('rooms null → location i building null', () {
        final model = LectureModel.fromJson(baseLectureJson(rooms: null));
        expect(model.location, isNull);
        expect(model.building, isNull);
      });

      test('rooms.building null → location i building null', () {
        final model = LectureModel.fromJson(
          baseLectureJson(rooms: {"name": "101", "building": null}),
        );
        expect(model.location, isNull);
        expect(model.building, isNull);
      });

      test('rooms.building.name null → location i building null', () {
        final model = LectureModel.fromJson(
          baseLectureJson(
            rooms: {"name": "101", "building": {"name": null}},
          ),
        );
        expect(model.location, isNull);
        expect(model.building, isNull);
      });

      test('pełne dane → location = "budynek sala", building = nazwa', () {
        final model = LectureModel.fromJson(
          baseLectureJson(rooms: roomEntry('Budynek A', '101')),
        );
        expect(model.location, 'Budynek A 101');
        expect(model.building, 'Budynek A');
      });
    });

    group('czas trwania', () {
      test('90 minut', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T08:00:00',
          endTime: '2026-03-23T09:30:00',
        ));
        expect(model.duration, '90 min');
      });

      test('45 minut', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T10:00:00',
          endTime: '2026-03-23T10:45:00',
        ));
        expect(model.duration, '45 min');
      });

      test('120 minut', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T12:00:00',
          endTime: '2026-03-23T14:00:00',
        ));
        expect(model.duration, '120 min');
      });
    });

    group('formatowanie godziny', () {
      test('godzina poranna z zerem', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T08:30:00',
          endTime: '2026-03-23T09:00:00',
        ));
        expect(model.startTime, '08:30');
        expect(model.endTime, '09:00');
      });

      test('godzina popołudniowa', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T13:45:00',
          endTime: '2026-03-23T15:15:00',
        ));
        expect(model.startTime, '13:45');
        expect(model.endTime, '15:15');
      });
    });

    group('pozostałe pola', () {
      test('id, name, group są poprawnie mapowane', () {
        final model = LectureModel.fromJson(baseLectureJson(
          id: 'xyz',
          subject: 'Fizyka',
          group: 'GR2',
        ));
        expect(model.id, 'xyz');
        expect(model.name, 'Fizyka');
        expect(model.group, 'GR2');
      });

      test('notes null → notes null', () {
        final model = LectureModel.fromJson(baseLectureJson(notes: null));
        expect(model.notes, isNull);
      });

      test('notes z wartością → zachowane', () {
        final model = LectureModel.fromJson(baseLectureJson(notes: 'Sala zmieniona'));
        expect(model.notes, 'Sala zmieniona');
      });

      test('date pochodzi z startTime', () {
        final model = LectureModel.fromJson(baseLectureJson(
          startTime: '2026-03-23T08:00:00',
          endTime: '2026-03-23T09:30:00',
        ));
        expect(model.date.year, 2026);
        expect(model.date.month, 3);
        expect(model.date.day, 23);
      });
    });
  });

  // ── BackendService.dateTimeToSupabase ──────────────────────

  group('BackendService.dateTimeToSupabase', () {
    final service = BackendService();

    test('formatuje datę do yyyy-MM-dd', () {
      expect(service.dateTimeToSupabase(DateTime(2026, 3, 28)), '2026-03-28');
    });

    test('dopełnia zerami miesiąc i dzień', () {
      expect(service.dateTimeToSupabase(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('grudzień', () {
      expect(service.dateTimeToSupabase(DateTime(2025, 12, 31)), '2025-12-31');
    });

    test('ignoruje godzinę', () {
      expect(
        service.dateTimeToSupabase(DateTime(2026, 6, 15, 23, 59, 59)),
        '2026-06-15',
      );
    });
  });
}
