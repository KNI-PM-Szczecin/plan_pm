import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/database_service.dart';

import 'package:plan_pm/global/logger.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    
    // Update Android Home Widget with grouped lectures
    await _updateHomeWidget(lectures);
  }

  Future<void> _updateHomeWidget(List<LectureModel> allLectures) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // We will prepare data for offsets between -30 and 30 days
      for (int offset = -30; offset <= 30; offset++) {
        final targetDate = today.add(Duration(days: offset));
        final dayLectures = allLectures.where((l) {
          final lDate = DateTime(l.date.year, l.date.month, l.date.day);
          return lDate.isAtSameMomentAs(targetDate);
        }).toList();
        
        // Sort by start time just to be sure
        dayLectures.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        final jsonList = dayLectures.asMap().entries.map((entry) {
          final idx = entry.key;
          final l = entry.value;
          return {
            "idx": idx,
            "name": l.name,
            "startTime": l.startTime,
            "endTime": l.endTime,
            "room": l.room,
            "building": l.building,
          };
        }).toList();
        
        final jsonStr = jsonEncode(jsonList);
        
        String dayNameStr;
        if (offset == 0) {
          dayNameStr = "Dzisiaj";
        } else if (offset == 1) {
          dayNameStr = "Jutro";
        } else if (offset == -1) {
          dayNameStr = "Wczoraj";
        } else {
          dayNameStr = DateFormat("EEEE, d MMM", "pl_PL").format(targetDate);
          // Capitalize first letter
          if (dayNameStr.isNotEmpty) {
            dayNameStr = dayNameStr[0].toUpperCase() + dayNameStr.substring(1);
          }
        }
        
        await HomeWidget.saveWidgetData("schedule_data_$offset", jsonStr);
        await HomeWidget.saveWidgetData("day_name_$offset", dayNameStr);
      }
      
      // Save global styles
      final prefs = await SharedPreferences.getInstance();
      final styleString = prefs.getString('event_color_style') ?? 'current';
      await HomeWidget.saveWidgetData("event_color_style", styleString);

      final primaryHex = '#${AppColor.primary.value.toRadixString(16).padLeft(8, '0')}';
      await HomeWidget.saveWidgetData("primary_color", primaryHex);
      
      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: 'ScheduleWidgetReceiver',
      );
      await HomeWidget.updateWidget(
        androidName: 'TodayWidgetReceiver',
      );
    } catch (e) {
      AppLogger.e("Failed to update home widget: $e");
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
