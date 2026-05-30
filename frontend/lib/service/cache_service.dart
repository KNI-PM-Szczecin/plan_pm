// Synchronizuje dane z backendu do lokalnego SQLite ([DatabaseService]).
// Singleton — jedna instancja przez cały cykl życia aplikacji.
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_utils.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:plan_pm/service/widget_service.dart';

class CacheService {
  static final CacheService _cacheService = CacheService._internal();

  CacheService._internal();
  factory CacheService() => _cacheService;

  final BackendService _backendService = BackendService();

  // Re-entrancy guards: równoległe wywołania zwracają to samo Future
  // zamiast startować kolejny sync (który by się przeplatał z bieżącym i
  // produkował duplikaty po `clearLectures` + insert loop).
  Future<void>? _lecturesSync;
  Future<void>? _newsSync;

  Future<void> syncLectures() {
    return _lecturesSync ??= _runLecturesSync().whenComplete(() {
      _lecturesSync = null;
    });
  }

  Future<void> _runLecturesSync() async {
    var lectures = await _backendService.fetchLectures();
    if (lectures.isEmpty) {
      AppLogger.w(
        "[CACHE-SERVICE] No lectures found in database. Maybe the user mistyped his info?",
      );
      return;
    }

    if (AppModeManager.current == AppMode.lecturer) {
      lectures = mergeLectures(lectures);
    }

    final db = DatabaseService.instance;
    await db.clearLectures();

    for (var lecture in lectures) {
      await db.addLecture(
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

    await WidgetService.pushTodayLectures();
  }

  Future<void> syncNews() {
    return _newsSync ??= _runNewsSync().whenComplete(() {
      _newsSync = null;
    });
  }

  Future<void> _runNewsSync() async {
    AppLogger.i("[CACHE-SERVICE] syncNews — start");
    final news = await _backendService.fetchNews();
    if (news.isEmpty) {
      AppLogger.w("[CACHE-SERVICE] syncNews — backend zwrócił 0 newsów");
      return;
    }
    final db = DatabaseService.instance;
    await db.clearNews();
    for (var singleNews in news) {
      await db.addNews(
        createdAt: singleNews.createdAt,
        title: singleNews.title,
        imageUrl: singleNews.imageUrl,
        content: singleNews.content,
        messageType: singleNews.messageType,
      );
    }
    AppLogger.i("[CACHE-SERVICE] syncNews — zapisano ${news.length} newsów do bazy");
  }
}
