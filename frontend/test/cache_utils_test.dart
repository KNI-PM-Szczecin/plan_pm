import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/service/cache_utils.dart';

LectureModel lecture({
  String id = 'lecture-1',
  String name = 'Mathematics',
  String startTime = '08:00',
  String endTime = '09:30',
  String group = 'L01/WI-S-AI-N/2024',
  DateTime? date,
  String? programName = 'Computer Science',
  String? notes = 'Bring calculator',
  int? year = 1,
  String? degreeLevel = 'Engineering',
}) {
  return LectureModel(
    id: id,
    name: name,
    startTime: startTime,
    endTime: endTime,
    room: '101',
    building: 'A',
    location: 'A 101',
    professor: 'dr Test',
    group: group,
    duration: '90 min',
    date: date ?? DateTime(2026, 3, 23, 8),
    notes: notes,
    programName: programName,
    year: year,
    degreeLevel: degreeLevel,
  );
}

void main() {
  group('mergeLectures', () {
    test('returns empty list for empty input', () {
      expect(mergeLectures([]), isEmpty);
    });

    test('keeps a single lecture unchanged', () {
      final original = lecture();

      final result = mergeLectures([original]);

      expect(result, hasLength(1));
      expect(result.single, same(original));
    });

    test('merges lectures from the same date and time slot', () {
      final result = mergeLectures([
        lecture(
          id: 'a',
          group: 'L01/WI-S-AI-N/2024',
          programName: 'Computer Science',
        ),
        lecture(
          id: 'b',
          group: 'L02/WI-S-AI-N/2024',
          programName: 'Automation',
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single.id, 'a');
      expect(result.single.group, 'L01,L02');
      expect(result.single.programName, 'Computer Science, Automation');
      expect(result.single.notes, 'Bring calculator');
    });

    test('deduplicates group codes and program names', () {
      final result = mergeLectures([
        lecture(group: 'L01/WI-S-AI-N/2024', programName: 'Computer Science'),
        lecture(group: 'L01/WI-S-AI-S/2024', programName: 'Computer Science'),
        lecture(group: ' L02/WI-S-AI-N/2024 ', programName: null),
      ]);

      expect(result, hasLength(1));
      expect(result.single.group, 'L01,L02');
      expect(result.single.programName, 'Computer Science');
    });

    test('keeps different time slots separate', () {
      final early = lecture(
        id: 'early',
        startTime: '08:00',
        endTime: '09:30',
        date: DateTime(2026, 3, 23, 8),
      );
      final late = lecture(
        id: 'late',
        startTime: '10:00',
        endTime: '11:30',
        date: DateTime(2026, 3, 23, 10),
      );

      final result = mergeLectures([late, early]);

      expect(result, hasLength(2));
      expect(result.map((lecture) => lecture.id), ['early', 'late']);
    });

    test('keeps same time slots on different dates separate', () {
      final firstDay = lecture(id: 'first-day', date: DateTime(2026, 3, 23, 8));
      final secondDay = lecture(
        id: 'second-day',
        date: DateTime(2026, 3, 24, 8),
      );

      final result = mergeLectures([secondDay, firstDay]);

      expect(result, hasLength(2));
      expect(result.map((lecture) => lecture.id), ['first-day', 'second-day']);
    });
  });
}
