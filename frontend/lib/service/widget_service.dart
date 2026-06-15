import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/service/database_service.dart';

class WidgetService {
  static const _appGroupId = 'group.com.piotrwittig.plan_pm';
  static const _androidName = 'ScheduleWidgetProvider';
  static const _iosName = 'PlanPMScheduleWidget';

  static const _debugLectures = [
    {'name': 'Bezpieczeństwo systemów', 'start': '08:00', 'end': '09:30', 'location': 'WChrobrego 208'},
    {'name': 'Bazy danych', 'start': '09:45', 'end': '11:15', 'location': 'WChrobrego 305'},
    {'name': 'Sieci komputerowe', 'start': '11:30', 'end': '13:00', 'location': 'WChrobrego 101'},
    {'name': 'Matematyka dyskretna', 'start': '13:15', 'end': '14:45', 'location': 'WChrobrego 204'},
    {'name': 'Algorytmy i struktury', 'start': '15:00', 'end': '16:30', 'location': 'WChrobrego 310'},
    {'name': 'Inżynieria oprogramowania', 'start': '16:45', 'end': '18:15', 'location': 'WChrobrego 112'},
    {'name': 'Aplikacje www', 'start': '20:30', 'end': '21:45', 'location': 'WChrobrego 112'},
    {'name': 'Programowanie obiektowe', 'start': '21:45', 'end': '23:00', 'location': 'WChrobrego 215'},
  ];

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> pushTodayLectures() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final today = DateUtils.dateOnly(DateTime.now());

      // Android reads this (today only) — payload kept unchanged.
      List<Map<String, String>> todays;
      // iOS reads this (a week ahead, each item carries its `date`) so the
      // WidgetKit timeline can roll over days and surface the live progress
      // bar at each lecture's start without the app being reopened.
      List<Map<String, String>> week;

      if (kDebugWidget) {
        final dateStr = _fmtDate(today);
        todays = _debugLectures.map((e) => Map<String, String>.from(e)).toList();
        week = _debugLectures
            .map((e) => {...Map<String, String>.from(e), 'date': dateStr})
            .toList();
        AppLogger.i('[WIDGET] Debug mode — using fake lecture data');
      } else {
        final all = await DatabaseService.instance.fetchLectures();
        final weekEnd = today.add(const Duration(days: 7));
        todays = all
            .where((l) => DateUtils.isSameDay(l.date, today))
            .map((l) => {
                  'name': l.name,
                  'start': l.startTime,
                  'end': l.endTime,
                  'location': l.location ?? '',
                })
            .toList();
        week = all.where((l) {
          final d = DateUtils.dateOnly(l.date);
          return !d.isBefore(today) && !d.isAfter(weekEnd);
        }).map((l) => {
              'name': l.name,
              'start': l.startTime,
              'end': l.endTime,
              'location': l.location ?? '',
              'date': _fmtDate(l.date),
            }).toList();
      }

      await HomeWidget.saveWidgetData<String>(
          'schedule_data', jsonEncode(todays));
      await HomeWidget.saveWidgetData<String>(
          'schedule_week', jsonEncode(week));
      await HomeWidget.updateWidget(
          androidName: _androidName, iOSName: _iosName);

      AppLogger.i(
          '[WIDGET] Pushed ${todays.length} lectures for today, ${week.length} for the week to home widget');
    } catch (e) {
      AppLogger.e('[WIDGET] Failed to push widget data: $e');
    }
  }
}
