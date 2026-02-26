import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/widgets/generic_loading.dart';
import 'package:plan_pm/global/widgets/generic_no_resource.dart';
import 'package:plan_pm/pages/home/widgets/home_section.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:collection/collection.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

List<LectureModel> getClosestLectures(
  List<LectureModel> lectures,
  DateTime referenceTime, {
  int count = 3,
}) {
  // Filter out past lectures
  final filtered = lectures.where((lecture) {
    final minutesDiff = lecture.date.difference(referenceTime).inMinutes;
    return minutesDiff >= 0;
  }).toList();

  // Sort those lectures by date from oldest to newest
  filtered.sort((a, b) {
    return a.date.compareTo(b.date);
  });
  // Take {count} from those lectures
  return filtered.take(count).toList();
}

class TodayLectures extends StatefulWidget {
  const TodayLectures({super.key});

  @override
  State<TodayLectures> createState() => _TodayLecturesState();
}

class _TodayLecturesState extends State<TodayLectures> {
  DateTime currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int idx = 0;
    final databaseService = DatabaseService.instance;
    return HomeSection(
      title: l10n.recentLecture,
      child: FutureBuilder<List<LectureModel>>(
        future: databaseService.fetchLectures(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return GenericNoResource(
              label: l10n.unexpectedError,
              icon: LucideIcons.bug,
              description: snapshot.error.toString(),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GenericLoading(label: l10n.lectureLoading);
          }
          final unfilteredLectures = snapshot.data ?? [];
          if (unfilteredLectures.isEmpty) {
            return GenericNoResource(
              label: l10n.todayLecturesNaN,
              icon: LucideIcons.calendarX,
              description: l10n.lectureWigetHint,
            );
          }

          final lectures = getClosestLectures(
            unfilteredLectures.where((lecture) {
              final lectureDate = lecture.date;
              return lectureDate.year == currentDate.year &&
                  lectureDate.month == currentDate.month;
            }).toList(),
            currentDate,
          );

          if (lectures.isEmpty) {
            return GenericNoResource(
              label: l10n.todayLecturesNaN,
              icon: LucideIcons.calendarX,
              description: l10n.lectureWigetHint,
            );
          }

          // Group those lectures by date
          Map<DateTime, List<LectureModel>> groups = groupBy(
            lectures,
            (lecture) => DateTime(
              lecture.date.year,
              lecture.date.month,
              lecture.date.day,
            ),
          );
          return Column(
            spacing: 10,
            children: [
              Skeletonizer(
                effect: const ShimmerEffect(baseColor: Color(0x4FFFFFFF)),
                enabled: snapshot.connectionState == ConnectionState.waiting,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: groups.keys.length,
                  itemBuilder: (context, index) {
                    final lectures = groups[groups.keys.toList()[index]];
                    final lecturesWidgets = lectures!.map((lecture) {
                      return Lecture(
                        idx: idx++,
                        name: lecture.name,
                        timeFrom: lecture.startTime,
                        timeTo: lecture.endTime,
                        location: lecture.location,
                        professor: lecture.professor,
                        group: lecture.group,
                        duration: lecture.duration,
                      );
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dateWithWeekday(groups.keys.toList()[index]),
                          style: TextStyle(color: AppColor.onBackgroundVariant),
                        ),
                        ...lecturesWidgets,
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
