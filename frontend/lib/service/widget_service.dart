import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/global/notifiers/locale_notifier.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lectures/utils/canceled_reason.dart';
import 'package:plan_pm/service/database_service.dart';

class WidgetService {
  static const _appGroupId = 'group.com.piotrwittig.plan_pm';
  // Three fixed-size Android widgets share the same data; update them all.
  static const _androidWidgetNames = [
    'ScheduleWidgetSmall',
    'ScheduleWidgetMedium',
    'ScheduleWidgetLarge',
  ];
  static const _iosName = 'PlanPMScheduleWidget';

  static const _debugLectures = [
    {'name': 'Bezpieczeństwo systemów', 'start': '09:45', 'end': '11:25', 'location': 'WChrobrego 208'},
    {'name': 'Bazy danych', 'start': '11:35', 'end': '13:10', 'location': 'WChrobrego 305'},
    {'name': 'Sieci komputerowe', 'start': '13:20', 'end': '15:00', 'location': 'WChrobrego 101'},
    {'name': 'Matematyka dyskretna', 'start': '15:10', 'end': '16:45', 'location': 'WChrobrego 204'},
    {'name': 'Aplikacje www', 'start': '19:30', 'end': '21:00', 'location': 'WChrobrego 112'},
    {'name': 'Programowanie obiektowe', 'start': '21:00', 'end': '22:00', 'location': 'WChrobrego 215'},
    {'name': 'Seminarium', 'start': '22:00', 'end': '23:30', 'location': 'WChrobrego 220'},
  ];

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // Localized strings for the widget without a BuildContext: prefer the in-app
  // language override, fall back to the system locale, then to Polish (the
  // template locale, matching the widget's other hardcoded Polish copy).
  static AppLocalizations _l10n() {
    final loc = localeNotifier.value ?? ui.PlatformDispatcher.instance.locale;
    const supported = {'pl', 'en', 'uk'};
    final code = supported.contains(loc.languageCode) ? loc.languageCode : 'pl';
    return lookupAppLocalizations(Locale(code));
  }

  // Maps a lecture's `notes` to the rector/canceled fields the native widgets
  // read: `rector` is the state key (logic), `badge` is the localized label.
  // Both are empty for ordinary lectures. Mirrors `canceledReasonFromNotes`.
  static ({String rector, String badge}) _rectorFields(
      String? notes, AppLocalizations l10n) {
    switch (canceledReasonFromNotes(notes)) {
      case CanceledReason.rectorHours:
        return (rector: 'hours', badge: l10n.rectorHoursBadge);
      case CanceledReason.rectorDay:
        return (rector: 'day', badge: l10n.rectorDayBadge);
      case CanceledReason.canceled:
        return (rector: 'canceled', badge: l10n.canceledClassBadge);
      case null:
        return (rector: '', badge: '');
    }
  }

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

      final l10n = _l10n();

      if (kDebugWidget) {
        final dateStr = _fmtDate(today);
        // Always mark the 2nd fake lecture as rector hours so the greyed-out /
        // textured / badged state is visible while iterating on the widget UI,
        // without needing the kDebugRectorHours flag. With kDebugRectorHours on,
        // every 3rd lecture is marked too.
        Map<String, String> decorate(int i, Map<String, String> e,
            {bool withDate = false}) {
          final m = Map<String, String>.from(e);
          if (i == 1 || (kDebugRectorHours && i % 3 == 0)) {
            m['rector'] = 'hours';
            m['badge'] = l10n.rectorHoursBadge;
          } else {
            m['rector'] = '';
            m['badge'] = '';
          }
          if (withDate) m['date'] = dateStr;
          return m;
        }

        final count = kDebugWidgetCount.clamp(0, _debugLectures.length);
        todays = [
          for (var i = 0; i < count; i++) decorate(i, _debugLectures[i])
        ];
        // iOS hides already-ended lectures (filterUpcoming) and keeps only the
        // current day, so the fixed daytime fixtures would vanish by evening.
        // Build an upcoming run starting "now" instead, dated per-lecture so it
        // stays correct across midnight. Android's payload (schedule_data, above)
        // is intentionally left untouched with the original fixed times.
        final base = DateTime.now();
        week = <Map<String, String>>[];
        for (var i = 0; i < count; i++) {
          final start = base.add(Duration(minutes: i * 25));
          final end = start.add(const Duration(minutes: 20));
          final m = decorate(i, {
            ..._debugLectures[i],
            'start': _fmtTime(start),
            'end': _fmtTime(end),
          });
          // Debug: mark the first (current-time) lecture as canceled so the
          // rector/canceled rendering is visible on iOS right now. iOS-only —
          // the Android payload (todays) is untouched.
          if (i == 0) {
            m['rector'] = 'canceled';
            m['badge'] = l10n.canceledClassBadge;
          }
          m['date'] = _fmtDate(DateUtils.dateOnly(start));
          week.add(m);
        }
        AppLogger.i('[WIDGET] Debug mode — using $count fake lecture(s)');
      } else {
        final all = await DatabaseService.instance.fetchLectures();
        final weekEnd = today.add(const Duration(days: 7));
        todays = all.where((l) => DateUtils.isSameDay(l.date, today)).map((l) {
          final r = _rectorFields(l.notes, l10n);
          return {
            'name': l.name,
            'start': l.startTime,
            'end': l.endTime,
            'location': l.location ?? '',
            'rector': r.rector,
            'badge': r.badge,
          };
        }).toList();
        week = all.where((l) {
          final d = DateUtils.dateOnly(l.date);
          return !d.isBefore(today) && !d.isAfter(weekEnd);
        }).map((l) {
          final r = _rectorFields(l.notes, l10n);
          return {
            'name': l.name,
            'start': l.startTime,
            'end': l.endTime,
            'location': l.location ?? '',
            'date': _fmtDate(l.date),
            'rector': r.rector,
            'badge': r.badge,
          };
        }).toList();
      }

      await HomeWidget.saveWidgetData<String>(
          'schedule_data', jsonEncode(todays));
      await HomeWidget.saveWidgetData<String>(
          'schedule_week', jsonEncode(week));
      for (final name in _androidWidgetNames) {
        await HomeWidget.updateWidget(androidName: name);
      }
      await HomeWidget.updateWidget(iOSName: _iosName);

      AppLogger.i(
          '[WIDGET] Pushed ${todays.length} lectures for today, ${week.length} for the week to home widget');
    } catch (e) {
      AppLogger.e('[WIDGET] Failed to push widget data: $e');
    }
  }
}
