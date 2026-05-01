import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';

// Znana data – poniedziałek 23 marca 2026
final monday = DateTime(2026, 3, 23);
final tuesday = DateTime(2026, 3, 24);
final wednesday = DateTime(2026, 3, 25);
final thursday = DateTime(2026, 3, 26);
final friday = DateTime(2026, 3, 27);
final saturday = DateTime(2026, 3, 28);
final sunday = DateTime(2026, 3, 29);

void main() {
  group('daysForward', () {
    group('tryb 7-dniowy', () {
      test('każdy dzień wraca 1', () {
        for (final date in [monday, tuesday, wednesday, thursday, friday, saturday, sunday]) {
          expect(daysForward(StudyMode.stationary, date.weekday, true), 1);
          expect(daysForward(StudyMode.notStationary, date.weekday, true), 1);
          expect(daysForward(null, date.weekday, true), 1);
        }
      });
    });

    group('stacjonarny', () {
      test('piątek → +3 (do poniedziałku)', () {
        expect(daysForward(StudyMode.stationary, friday.weekday, false), 3);
      });

      test('pozostałe dni → +1', () {
        for (final date in [monday, tuesday, wednesday, thursday]) {
          expect(daysForward(StudyMode.stationary, date.weekday, false), 1);
        }
      });
    });

    group('niestacjonarny', () {
      test('niedziela → +5 (do piątku)', () {
        expect(daysForward(StudyMode.notStationary, sunday.weekday, false), 5);
      });

      test('piątek i sobota → +1', () {
        expect(daysForward(StudyMode.notStationary, friday.weekday, false), 1);
        expect(daysForward(StudyMode.notStationary, saturday.weekday, false), 1);
      });
    });
  });

  group('daysBackward', () {
    group('tryb 7-dniowy', () {
      test('poniedziałek → -6 (do niedzieli)', () {
        expect(daysBackward(StudyMode.stationary, monday.weekday, true), 6);
        expect(daysBackward(null, monday.weekday, true), 6);
      });

      test('pozostałe dni → -1', () {
        for (final date in [tuesday, wednesday, thursday, friday, saturday, sunday]) {
          expect(daysBackward(StudyMode.stationary, date.weekday, true), 1);
        }
      });
    });

    group('stacjonarny', () {
      test('poniedziałek → -3 (do piątku)', () {
        expect(daysBackward(StudyMode.stationary, monday.weekday, false), 3);
      });

      test('pozostałe dni → -1', () {
        for (final date in [tuesday, wednesday, thursday, friday]) {
          expect(daysBackward(StudyMode.stationary, date.weekday, false), 1);
        }
      });
    });

    group('niestacjonarny', () {
      test('piątek → -5 (do niedzieli)', () {
        expect(daysBackward(StudyMode.notStationary, friday.weekday, false), 5);
      });

      test('sobota i niedziela → -1', () {
        expect(daysBackward(StudyMode.notStationary, saturday.weekday, false), 1);
        expect(daysBackward(StudyMode.notStationary, sunday.weekday, false), 1);
      });
    });
  });

  group('visibleDayIndices', () {
    test('tryb 7-dniowy → wszystkie 7 dni (0..6)', () {
      expect(visibleDayIndices(StudyMode.stationary, true), [0, 1, 2, 3, 4, 5, 6]);
      expect(visibleDayIndices(StudyMode.notStationary, true), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('stacjonarny → poniedziałek–piątek (0..4)', () {
      expect(visibleDayIndices(StudyMode.stationary, false), [0, 1, 2, 3, 4]);
    });

    test('niestacjonarny → piątek–niedziela (4..6)', () {
      expect(visibleDayIndices(StudyMode.notStationary, false), [4, 5, 6]);
    });

    test('null → domyślnie stacjonarny (0..4)', () {
      expect(visibleDayIndices(null, false), [0, 1, 2, 3, 4]);
    });
  });

  group('adjustInitialDate', () {
    group('stacjonarny', () {
      test('sobota → następny poniedziałek (+2)', () {
        final result = adjustInitialDate(StudyMode.stationary, saturday);
        expect(result, saturday.add(const Duration(days: 2)));
        expect(result.weekday, DateTime.monday);
      });

      test('niedziela → następny poniedziałek (+1)', () {
        final result = adjustInitialDate(StudyMode.stationary, sunday);
        expect(result, sunday.add(const Duration(days: 1)));
        expect(result.weekday, DateTime.monday);
      });

      test('dni robocze → bez zmian', () {
        for (final date in [monday, tuesday, wednesday, thursday, friday]) {
          expect(adjustInitialDate(StudyMode.stationary, date), date);
        }
      });
    });

    group('niestacjonarny', () {
      test('poniedziałek → piątek (+4)', () {
        final result = adjustInitialDate(StudyMode.notStationary, monday);
        expect(result, monday.add(const Duration(days: 4)));
        expect(result.weekday, DateTime.friday);
      });

      test('wtorek → piątek (+3)', () {
        final result = adjustInitialDate(StudyMode.notStationary, tuesday);
        expect(result, tuesday.add(const Duration(days: 3)));
        expect(result.weekday, DateTime.friday);
      });

      test('środa → piątek (+2)', () {
        final result = adjustInitialDate(StudyMode.notStationary, wednesday);
        expect(result, wednesday.add(const Duration(days: 2)));
        expect(result.weekday, DateTime.friday);
      });

      test('czwartek → piątek (+1)', () {
        final result = adjustInitialDate(StudyMode.notStationary, thursday);
        expect(result, thursday.add(const Duration(days: 1)));
        expect(result.weekday, DateTime.friday);
      });

      test('piątek, sobota, niedziela → bez zmian', () {
        for (final date in [friday, saturday, sunday]) {
          expect(adjustInitialDate(StudyMode.notStationary, date), date);
        }
      });
    });
  });
}
