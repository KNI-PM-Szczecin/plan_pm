import 'package:plan_pm/api/models/lecture_model.dart';

// Merges lecturer classes that share the same day and time slot.
//
// The backend returns one row per group, while the UI expects a single lecture
// entry with combined group codes and program names.
List<LectureModel> mergeLectures(List<LectureModel> lectures) {
  final Map<String, List<LectureModel>> slots = {};
  for (final lecture in lectures) {
    final key =
        '${lecture.date.year}-${lecture.date.month}-${lecture.date.day}_'
        '${lecture.startTime}_${lecture.endTime}';
    slots.putIfAbsent(key, () => []).add(lecture);
  }

  final result = <LectureModel>[];
  for (final group in slots.values) {
    if (group.length == 1) {
      result.add(group.first);
      continue;
    }

    final first = group.first;

    final codes = <String>[];
    for (final lecture in group) {
      final code = lecture.group.split('/').first.trim();
      if (!codes.contains(code)) codes.add(code);
    }

    final programs = <String>[];
    for (final lecture in group) {
      final programName = lecture.programName;
      if (programName != null && !programs.contains(programName)) {
        programs.add(programName);
      }
    }

    result.add(
      LectureModel(
        id: first.id,
        name: first.name,
        startTime: first.startTime,
        endTime: first.endTime,
        room: first.room,
        building: first.building,
        location: first.location,
        professor: first.professor,
        group: codes.join(','),
        duration: first.duration,
        date: first.date,
        notes: first.notes,
        programName: programs.isEmpty ? null : programs.join(', '),
        year: first.year,
        degreeLevel: first.degreeLevel,
      ),
    );
  }

  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}
