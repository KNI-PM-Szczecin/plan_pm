import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/service/database_service.dart';

class WidgetService {
  static const _appGroupId = 'group.com.piotrwittig.plan_pm';
  static const _androidName = 'ScheduleWidgetProvider';
  static const _iosName = 'PlanPMScheduleWidget';

  static Future<void> pushTodayLectures() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final all = await DatabaseService.instance.fetchLectures();
      final today = DateTime.now();
      final todays = all
          .where((l) => DateUtils.isSameDay(l.date, today))
          .map((l) => {
                'name': l.name,
                'start': l.startTime,
                'end': l.endTime,
                'location': l.location ?? '',
              })
          .toList();

      await HomeWidget.saveWidgetData<String>(
          'schedule_data', jsonEncode(todays));
      await HomeWidget.updateWidget(
          androidName: _androidName, iOSName: _iosName);

      AppLogger.i(
          '[WIDGET] Pushed ${todays.length} lectures for today to home widget');
    } catch (e) {
      AppLogger.e('[WIDGET] Failed to push widget data: $e');
    }
  }
}
