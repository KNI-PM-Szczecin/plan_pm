// Funkcje filtrujące i sortujące zajęcia na potrzeby widżetu [TodayLectures].
import 'package:plan_pm/api/models/lecture_model.dart';

// Zwraca [count] najbliższych zajęć względem [referenceTime].
// Uwzględnia zajęcia, które jeszcze się nie skończyły (w trakcie lub nadchodzące).
List<LectureModel> getClosestLectures(
  List<LectureModel> lectures,
  DateTime referenceTime, {
  int count = 3,
}) {
  final filtered = lectures.where((lecture) {
    final endTimeParts = lecture.endTime.split(':');
    final endHour = int.tryParse(endTimeParts[0]) ?? 0;
    final endMinute = int.tryParse(endTimeParts[1]) ?? 0;
    final lectureEnd = DateTime(
      lecture.date.year,
      lecture.date.month,
      lecture.date.day,
      endHour,
      endMinute,
    );
    return !lectureEnd.isBefore(referenceTime);
  }).toList()
    ..sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.startTime.compareTo(b.startTime);
    });

  return filtered.take(count).toList();
}
