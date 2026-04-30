import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/database_service.dart';

class CacheService {
  static final CacheService _cacheService = CacheService._internal();

  CacheService._internal();
  factory CacheService() {
    return _cacheService;
  }
  final BackendService _backendService = BackendService();

  Future<void> syncLectures() async {
    var lectures = await _backendService.fetchLectures();
    if (lectures.isEmpty) {
      AppLogger.w(
        "[CACHE-SERVICE] No lectures found in database. Maybe the user mistyped his info?",
      );
      return;
    }

    if (AppModeManager.current == AppMode.lecturer) {
      lectures = _mergeLectures(lectures);
    }

    final DatabaseService databaseService = DatabaseService.instance;
    await databaseService.clearLectures();

    for (var lecture in lectures) {
      await databaseService.addLecture(
        name: lecture.name,
        startTime: lecture.startTime,
        endTime: lecture.endTime,
        room: lecture.room,
        building: lecture.building,
        location: lecture.location,
        professor: lecture.professor,
        group: lecture.group,
        duration: lecture.duration,
        date: lecture.date,
        programName: lecture.programName,
        year: lecture.year,
        degreeLevel: lecture.degreeLevel,
      );
    }
  }

  List<LectureModel> _mergeLectures(List<LectureModel> lectures) {
    final Map<String, List<LectureModel>> slots = {};
    for (final l in lectures) {
      final key =
          '${l.date.year}-${l.date.month}-${l.date.day}_${l.startTime}_${l.endTime}';
      slots.putIfAbsent(key, () => []).add(l);
    }

    final result = <LectureModel>[];
    for (final group in slots.values) {
      if (group.length == 1) {
        result.add(group.first);
        continue;
      }
      final first = group.first;

      final codes = <String>[];
      for (final l in group) {
        final code = l.group.split('/').first.trim();
        if (!codes.contains(code)) codes.add(code);
      }

      final programs = <String>[];
      for (final l in group) {
        if (l.programName != null && !programs.contains(l.programName)) {
          programs.add(l.programName!);
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

  Future<void> syncNews() async {
    final news = await _backendService.fetchNews();
    if (news.isEmpty) {
      AppLogger.w("[CACHE-SERVICE] No news found. Maybe the internet is down?");
      return;
    }
    final DatabaseService databaseService = DatabaseService.instance;
    await databaseService.clearNews();

    for (var singleNews in news) {
      await databaseService.addNews(
        createdAt: singleNews.createdAt,
        title: singleNews.title,
        imageUrl: singleNews.imageUrl,
        content: singleNews.content,
        messageType: singleNews.messageType,
      );
    }
  }
}
