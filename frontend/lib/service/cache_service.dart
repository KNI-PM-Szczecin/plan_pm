import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/database_service.dart';

import 'package:plan_pm/global/logger.dart';

class CacheService {
  static final CacheService _cacheService = CacheService._internal();

  CacheService._internal();
  factory CacheService() {
    return _cacheService;
  }
  final BackendService _backendService = BackendService();

  Future<void> syncLectures() async {
    final lectures = await _backendService.fetchLectures();
    if (lectures.isEmpty) {
      AppLogger.w(
        "[CACHE-SERVICE] No lectures found in database. Maybe the user mistyped his info?",
      );
      return;
    }

    final DatabaseService databaseService = DatabaseService.instance;
    await databaseService.clearLectures();

    for (var lecture in lectures) {
      databaseService.addLecture(
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
      );
    }
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
      databaseService.addNews(
        createdAt: singleNews.createdAt,
        title: singleNews.title,
        imageUrl: singleNews.imageUrl,
        content: singleNews.content,
        messageType: singleNews.messageType,
      );
    }
  }
}
