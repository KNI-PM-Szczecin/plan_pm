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
  group('nextWeek / previousWeek', () {
    test('przesuwa dokładnie o 7 dni', () {
      expect(nextWeek(monday), DateTime(2026, 3, 30));
      expect(previousWeek(monday), DateTime(2026, 3, 16));
    });

    test('zachowuje dzień tygodnia', () {
      for (final date in [monday, tuesday, wednesday, thursday, friday, saturday, sunday]) {
        expect(nextWeek(date).weekday, date.weekday);
        expect(previousWeek(date).weekday, date.weekday);
      }
    });

    test('są wzajemnie odwrotne', () {
      for (final date in [monday, wednesday, sunday]) {
        expect(previousWeek(nextWeek(date)), date);
        expect(nextWeek(previousWeek(date)), date);
      }
    });

    test('przechodzi przez granicę miesiąca i roku', () {
      expect(nextWeek(DateTime(2026, 10, 28)), DateTime(2026, 11, 4));
      expect(previousWeek(DateTime(2027, 1, 4)), DateTime(2026, 12, 28));
    });

    test('zachowuje godzinę', () {
      final withTime = DateTime(2026, 3, 23, 14, 35, 12);
      expect(nextWeek(withTime), DateTime(2026, 3, 30, 14, 35, 12));
    });

    // Duration(days: 7) to dokładne 168 h, więc przy zmianie czasu skok
    // wypadłby godzinę obok i tuż po północy cofnąłby się o dzień. Konstruktor
    // DateTime liczy kalendarzowo, więc data jest poprawna w każdej strefie.
    test('poprawne przy zmianie czasu (DST)', () {
      // W Polsce czas zmienia się 29.03.2026 i 25.10.2026.
      final beforeSpring = DateTime(2026, 3, 25, 0, 30);
      expect(nextWeek(beforeSpring), DateTime(2026, 4, 1, 0, 30));

      final beforeAutumn = DateTime(2026, 10, 21, 0, 30);
      expect(nextWeek(beforeAutumn), DateTime(2026, 10, 28, 0, 30));
      expect(previousWeek(DateTime(2026, 10, 28, 0, 30)), beforeAutumn);
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
