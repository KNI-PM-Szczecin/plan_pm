// Testy dostępności kombinacji studiów — po jednym teście na każdy kierunek.
//
// Fixture to zrzut produkcji (struktura + wiersze v_unique_groups), więc te
// testy sprawdzają realne dane uczelni, a nie wymyślony przypadek. Regenerację
// robi backend/scripts/dump_availability_fixture.py.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/service/program_availability.dart';

({List<StructureEntry> structure, List<ProgramRow> programs}) loadSnapshot() {
  final raw = File('test/fixtures/availability_snapshot.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final structure = (json['structure'] as List)
      .map(
        (e) => StructureEntry(
          faculty: e['faculty'] as String,
          degreeCourse: e['degreeCourse'] as String,
          specialisation: e['specialisation'] as String?,
        ),
      )
      .toList();
  final programs = (json['programs'] as List)
      .map(
        (e) => ProgramRow(
          programName: e['programName'] as String,
          year: e['year'] as int,
          programType: e['programType'] as String,
          degreeLevel: e['degreeLevel'] as String,
        ),
      )
      .toList();
  return (structure: structure, programs: programs);
}

void main() {
  final snapshot = loadSnapshot();
  final availability = ProgramAvailability.from(
    structure: snapshot.structure,
    programs: snapshot.programs,
  );

  // Wszystkie kierunki z drzewka, także te bez planów — każdy dostaje własny test.
  final degreeCourses = <String, String>{}; // "wydział|kierunek" -> kierunek
  for (final entry in snapshot.structure) {
    degreeCourses['${entry.faculty}|${entry.degreeCourse}'] = entry.degreeCourse;
  }

  group('kaskada formularza nie prowadzi donikąd', () {
    for (final key in degreeCourses.keys.toList()..sort()) {
      final faculty = key.split('|').first;
      final degreeCourse = degreeCourses[key]!;

      test('$faculty — $degreeCourse', () {
        final courses = availability.degreeCourses(faculty);
        if (!courses.contains(degreeCourse)) {
          // Kierunek bez żadnego opublikowanego planu (np. "Oceanotechnika")
          // nie może się w ogóle pojawić na liście — inaczej student wejdzie
          // w ślepą uliczkę.
          expect(
            availability.filter(faculty: faculty, degreeCourse: degreeCourse),
            isEmpty,
            reason: 'kierunek ukryty, ale ma pasujące plany',
          );
          return;
        }

        final specChoices = availability.specialisationChoices(
          faculty: faculty,
          degreeCourse: degreeCourse,
        );
        expect(
          specChoices,
          isNotEmpty,
          reason: 'kierunek widoczny, ale nie ma czego wybrać',
        );

        var resolvedPaths = 0;
        for (final spec in specChoices) {
          final specKey = spec.specialisationKey;
          final years = availability.years(
            faculty: faculty,
            degreeCourse: degreeCourse,
            specialisationKey: specKey,
          );
          expect(years, isNotEmpty, reason: 'specjalizacja bez roku: $specKey');

          for (final year in years) {
            final levels = availability.degreeLevels(
              faculty: faculty,
              degreeCourse: degreeCourse,
              specialisationKey: specKey,
              year: year,
            );
            expect(levels, isNotEmpty, reason: 'rok bez stopnia: $specKey/$year');

            for (final level in levels) {
              final types = availability.programTypes(
                faculty: faculty,
                degreeCourse: degreeCourse,
                specialisationKey: specKey,
                year: year,
                degreeLevel: level,
              );
              expect(
                types,
                isNotEmpty,
                reason: 'stopień bez trybu: $specKey/$year/$level',
              );

              for (final type in types) {
                final option = availability.resolve(
                  faculty: faculty,
                  degreeCourse: degreeCourse,
                  specialisationKey: specKey,
                  year: year,
                  programType: type,
                  degreeLevel: level,
                );
                expect(
                  option,
                  isNotNull,
                  reason: 'ślepa uliczka: $specKey/$year/$level/$type',
                );
                expect(option!.programName, isNotEmpty);
                resolvedPaths++;
              }
            }
          }
        }
        expect(resolvedPaths, greaterThan(0));
      });
    }
  });

  group('zgłoszenia z 09.2026', () {
    test('Mechanika i Budowa Maszyn rok 2 nie oferuje "brak specjalizacji"', () {
      // Zgłoszenie z 16.09: student wybrał kierunek bez specjalizacji i dostał
      // pustą listę grup. Plan roku 2 jest wystawiony pod specjalizacjami.
      final choices = availability.specialisationChoices(
        faculty: 'Mechaniczny',
        degreeCourse: 'Mechanika i Budowa Maszyn',
        year: 2,
        degreeLevel: 'inż.',
        programType: 'S',
      );
      expect(choices, isNotEmpty);
      expect(
        choices.where((c) => c.specialisation == null),
        isEmpty,
        reason: '"brak specjalizacji" dla roku 2 prowadzi donikąd',
      );
      expect(
        choices.map((c) => c.specialisation),
        containsAll(<String>[
          'Diagnostyka i Remonty Maszyn i Urządzeń Okrętowych',
          'Eksploatacja Siłowni Okrętowych',
        ]),
      );
    });

    test('Mechanika i Budowa Maszyn rok 1 oferuje plan pod kierunkiem', () {
      final choices = availability.specialisationChoices(
        faculty: 'Mechaniczny',
        degreeCourse: 'Mechanika i Budowa Maszyn',
        year: 1,
        degreeLevel: 'inż.',
        programType: 'S',
      );
      expect(choices.map((c) => c.specialisation), contains(null));
    });

    test('Transport rok 3 ma Logistykę Transportu Zintegrowanego', () {
      // Zgłoszenie z 17.09: specjalizacja istniała w planach, ale nie w strukturze.
      final choices = availability.specialisationChoices(
        faculty: 'Inżynieryjno-Ekonomiczny Transportu',
        degreeCourse: 'Transport',
        year: 3,
        degreeLevel: 'inż.',
        programType: 'S',
      );
      expect(
        choices.map((c) => c.specialisation),
        contains('Logistyka Transportu Zintegrowanego'),
      );
    });

    test('specjalizacja z podwójną spacją w bazie jest dopasowana', () {
      // "Inżynieria i Bezpieczeństwo  w Transporcie Drogowym" — dwie spacje w
      // planach, jedna w strukturze. Bez normalizacji rocznik znikał z apki.
      // Przypadek jest zbudowany ręcznie, a nie brany ze snapshotu: parser już
      // zwija spacje, więc po najbliższym przebiegu pipeline'u produkcja ich
      // nie ma, a regresja i tak musi zostać przypilnowana.
      final withDoubleSpace = ProgramAvailability.from(
        structure: const [
          StructureEntry(
            faculty: 'Inżynieryjno-Ekonomiczny Transportu',
            degreeCourse: 'Transport',
            specialisation: 'Inżynieria i Bezpieczeństwo w Transporcie Drogowym',
          ),
        ],
        programs: const [
          ProgramRow(
            programName: 'Inżynieria i Bezpieczeństwo  w Transporcie Drogowym',
            year: 4,
            programType: 'S',
            degreeLevel: 'inż.',
          ),
        ],
      );
      expect(withDoubleSpace.unmatchedProgramNames, isEmpty);
      expect(withDoubleSpace.options, hasLength(1));
      // Do zapytania idzie nazwa z bazy, nie etykieta z drzewka.
      expect(withDoubleSpace.options.first.programName, contains('  '));
      expect(
        withDoubleSpace.options.first.specialisation,
        'Inżynieria i Bezpieczeństwo w Transporcie Drogowym',
      );
    });

    test('specjalizacja z podwójną spacją jest wybieralna w snapshocie', () {
      expect(
        availability.options.where(
          (o) =>
              o.specialisation ==
              'Inżynieria i Bezpieczeństwo w Transporcie Drogowym',
        ),
        isNotEmpty,
      );
    });
  });

  group('ścieżka językowa', () {
    test('"Transport Morski ang." jest osobnym wariantem tej samej specjalizacji', () {
      final english = availability.options.where((o) => o.language != null).toList();
      expect(english, isNotEmpty);
      for (final option in english) {
        expect(option.specialisation ?? option.degreeCourse, isNot(contains('ang')));
        expect(option.programName.toLowerCase(), contains('ang'));
      }
    });

    test('klucz specjalizacji odróżnia ścieżkę polską od angielskiej', () {
      const pl = ProgramOption(
        faculty: 'F',
        degreeCourse: 'K',
        specialisation: 'Transport Morski',
        year: 2,
        programType: 'S',
        degreeLevel: 'inż.',
        programName: 'Transport Morski',
        language: null,
      );
      const en = ProgramOption(
        faculty: 'F',
        degreeCourse: 'K',
        specialisation: 'Transport Morski',
        year: 2,
        programType: 'S',
        degreeLevel: 'inż.',
        programName: 'Transport Morski ang.',
        language: 'ang.',
      );
      expect(pl.specialisationKey, isNot(en.specialisationKey));
    });

    test('polski znacznik nie tworzy wariantu, angielski tak', () {
      expect(splitLanguageSuffix('Informatyka POL').language, isNull);
      expect(splitLanguageSuffix('Informatyka pol.').language, isNull);
      expect(splitLanguageSuffix('Informatyka ANG').language, 'ANG');
      expect(splitLanguageSuffix('Informatyka ang.').language, 'ang.');
      expect(splitLanguageSuffix('Informatyka').language, isNull);
      expect(splitLanguageSuffix('ANG').language, isNull,
          reason: 'sama końcówka nie jest nazwą planu');
    });
  });

  group('sygnał rozjazdu nazw', () {
    test('snapshot produkcji nie ma planów bez węzła w strukturze', () {
      expect(
        availability.unmatchedProgramNames,
        isEmpty,
        reason: 'plan, którego nie da się wybrać w aplikacji',
      );
    });

    test('nieznana nazwa planu ląduje w unmatched, a nie w opcjach', () {
      final withGhost = ProgramAvailability.from(
        structure: snapshot.structure,
        programs: [
          ...snapshot.programs,
          const ProgramRow(
            programName: 'Kierunek Widmo',
            year: 1,
            programType: 'S',
            degreeLevel: 'inż.',
          ),
        ],
      );
      expect(withGhost.unmatchedProgramNames, ['Kierunek Widmo']);
      expect(
        withGhost.options.where((o) => o.programName == 'Kierunek Widmo'),
        isEmpty,
      );
    });
  });

  group('normalizacja nazw', () {
    test('zwija podwójne i twarde spacje', () {
      expect(normalizeProgramName('A  B'), 'a b');
      expect(normalizeProgramName('A B'), 'a b');
      expect(normalizeProgramName('  A B  '), 'a b');
    });
  });
}
