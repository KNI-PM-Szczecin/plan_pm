// Testy klasyfikacji grup — po jednym teście na każdy plan z przedmiotami
// obieralnymi, na realnych kodach ze snapshotu produkcji.
//
// Zgłoszenia (3×): "można wybrać tylko jeden przedmiot obieralny, przez co plan
// jest niepełny". Grupa projektowa rocznika i cała pula WIET lądowały w jednym
// worku "Inne" z pojedynczym wyborem.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/service/group_categories.dart';

Map<String, List<String>> loadGroupsByPlan() {
  final raw = File('test/fixtures/availability_snapshot.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['groups'] as Map<String, dynamic>).map(
    (key, value) => MapEntry(key, (value as List).cast<String>()),
  );
}

void main() {
  final groupsByPlan = loadGroupsByPlan();

  // Plany, w których uczelnia wystawia pulę obieralnych — tylko tam student
  // musi zaznaczyć kilka pozycji naraz.
  final plansWithElectives = groupsByPlan.entries
      .where((e) => e.value.any((g) => classifyGroup(g) == GroupKind.elective))
      .map((e) => e.key)
      .toList()
    ..sort();

  test('snapshot w ogóle zawiera plany z obieralnymi', () {
    expect(plansWithElectives, isNotEmpty);
  });

  group('plan z przedmiotami obieralnymi', () {
    for (final plan in plansWithElectives) {
      test(plan, () {
        final groups = groupsByPlan[plan]!;
        final sections = buildGroupSections(groups);

        // Nic nie ginie po drodze.
        expect(
          sections.expand((s) => s.entries).map((e) => e.full).toSet(),
          groups.toSet(),
        );

        final elective = sections.singleWhere(
          (s) => s.kind == GroupKind.elective,
        );
        expect(
          elective.multiSelect,
          isTrue,
          reason: 'obieralnych wybiera się kilka naraz',
        );
        expect(elective.entries, isNotEmpty);
        for (final entry in elective.entries) {
          expect(
            entry.pool.toUpperCase(),
            startsWith('WIET'),
            reason: '${entry.code} nie pochodzi z puli obieralnych',
          );
        }

        // Grupy rocznika zostają pojedynczym wyborem — także projektowa, która
        // wcześniej konkurowała o ten sam slot co obieralne.
        for (final section in sections.where((s) => s.kind != GroupKind.elective)) {
          expect(
            section.multiSelect,
            isFalse,
            reason: 'do grupy ${section.kind} należy się jednej',
          );
          for (final entry in section.entries) {
            expect(entry.pool.toUpperCase(), isNot(startsWith('WIET')));
          }
        }

        // Nic nie zostaje w koszu "Inne" — każdy kod ma rozpoznany typ.
        expect(
          sections.where((s) => s.kind == GroupKind.other),
          isEmpty,
          reason: 'nierozpoznany kod grupy w planie $plan',
        );
      });
    }
  });

  group('plan bez obieralnych', () {
    final plansWithout = groupsByPlan.keys
        .where((k) => !plansWithElectives.contains(k))
        .toList()
      ..sort();

    test('żaden nie dostaje sekcji wielokrotnego wyboru', () {
      expect(plansWithout, isNotEmpty);
      for (final plan in plansWithout) {
        final sections = buildGroupSections(groupsByPlan[plan]!);
        expect(
          sections.where((s) => s.multiSelect),
          isEmpty,
          reason: plan,
        );
      }
    });
  });

  group('klasyfikacja kodów', () {
    test('rozpoznaje typy grup rocznika', () {
      expect(classifyGroup('A01/LTZ/2024/2025 ZS'), GroupKind.auditorium);
      expect(classifyGroup('C01/LTZ/2024/2025 ZS'), GroupKind.classes);
      expect(classifyGroup('L02/ESO/2024/2025 ZS'), GroupKind.labs);
      expect(classifyGroup('P01/LTZ/2024/2025 ZS'), GroupKind.project);
      expect(classifyGroup('SYM02/ESO/2024/2025 ZS'), GroupKind.simulator);
    });

    test('rozpoznaje obieralne po kodzie i po puli', () {
      expect(classifyGroup('P0A04/WIET/2024/2025 ZS'), GroupKind.elective);
      expect(classifyGroup('P0L04A/WIET/2024/2025 ZS'), GroupKind.elective);
      expect(classifyGroup('P0C03B/WIET/2024/2025 ZS'), GroupKind.elective);
      expect(classifyGroup('A01/WIET MGR/2025/2026 LS'), GroupKind.elective);
    });

    test('grupa projektowa rocznika nie jest obieralną', () {
      // "P01" vs "P0A01" — jedyna różnica to litera typu po numerze puli.
      expect(classifyGroup('P01/LTZ/2024/2025 ZS'), isNot(GroupKind.elective));
      expect(classifyGroup('P02/ESW/2023/2024 ZS'), isNot(GroupKind.elective));
    });

    test('nieznany kod nie wywraca ekranu', () {
      expect(classifyGroup('XYZ9/ABC/2024/2025 ZS'), GroupKind.other);
      expect(classifyGroup('bezukośnika'), GroupKind.other);
    });
  });

  group('budowanie sekcji', () {
    test('kolejność: rocznik najpierw, obieralne na końcu', () {
      final sections = buildGroupSections([
        'P0A04/WIET/2024/2025 ZS',
        'L01/LTZ/2024/2025 ZS',
        'A01/LTZ/2024/2025 ZS',
        'P01/LTZ/2024/2025 ZS',
        'C01/LTZ/2024/2025 ZS',
      ]);
      expect(sections.map((s) => s.kind), [
        GroupKind.auditorium,
        GroupKind.classes,
        GroupKind.labs,
        GroupKind.project,
        GroupKind.elective,
      ]);
    });

    test('sortuje po numerze, nie alfabetycznie', () {
      final sections = buildGroupSections([
        'L10/INF/2025/2026 ZS',
        'L02/INF/2025/2026 ZS',
        'L01/INF/2025/2026 ZS',
      ]);
      expect(
        sections.single.entries.map((e) => e.code),
        ['L01', 'L02', 'L10'],
      );
    });

    test('pomija puste wpisy', () {
      expect(buildGroupSections(['', '   ']), isEmpty);
    });
  });
}
