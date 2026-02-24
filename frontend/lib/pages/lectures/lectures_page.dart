import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/widgets/generic_loading.dart';
import 'package:plan_pm/global/widgets/generic_no_resource.dart';
import 'package:plan_pm/global/app_time.dart';
import 'package:plan_pm/pages/lectures/widgets/day_selection.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LecturesPage extends StatefulWidget {
  const LecturesPage({super.key});

  @override
  State<LecturesPage> createState() => _LecturesPageState();
}

class _LecturesPageState extends State<LecturesPage> {
  int currentWeekDay = AppTime.now().weekday - 1;

  DateTime now = AppTime.now();
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    if (now.weekday == DateTime.saturday) {
      // Saturday -> next Monday
      currentDate = now.add(Duration(days: 2));
    } else if (now.weekday == DateTime.sunday) {
      // Sunday -> next Monday
      currentDate = now.add(Duration(days: 1));
    } else {
      currentDate = now;
    }
  }

  late int selectedDay = currentDate.weekday - 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final databaseService = DatabaseService.instance;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DaySelection(
            currentDate: currentDate,
            defaultSelected: selectedDay,
            onChange: (selectedDay, selectedDate) {
              setState(() {
                selectedDay = selectedDay;
                currentDate = selectedDate;
              });
            },
          ),
        ),
        FutureBuilder<List<LectureModel>>(
          future: databaseService.fetchLectures(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GenericNoResource(
                  label: l10n.unexpectedError,
                  icon: LucideIcons.bug,
                  description: snapshot.error.toString(),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: GenericLoading(label: l10n.lectureLoading),
                  ),
                ),
              );
            }

            final unfilteredLectures = snapshot.data ?? [];

            final lectures = unfilteredLectures.where((lecture) {
              final lectureDate = lecture.date;
              return lectureDate.year == currentDate.year &&
                  lectureDate.month == currentDate.month &&
                  lectureDate.day == currentDate.day;
            }).toList();

            if (lectures.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GenericNoResource(
                  label: l10n.todayDataNaN,
                  icon: LucideIcons.calendarX,
                  description: l10n.lectureWigetHint,
                ),
              );
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.lectureLength(lectures.length),
                          style: TextStyle(color: AppColor.onBackgroundVariant),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Skeletonizer(
                        effect: const ShimmerEffect(
                          baseColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        enabled:
                            snapshot.connectionState == ConnectionState.waiting,
                        child: ListView.separated(
                          itemCount: lectures.length,
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 5);
                          },
                          itemBuilder: (context, index) {
                            final lecture = lectures[index];
                            return Lecture(
                              idx: index,
                              name: lecture.name,
                              timeFrom: lecture.startTime,
                              timeTo: lecture.endTime,
                              location: lecture.location,
                              professor: lecture.professor,
                              group: lecture.group,
                              duration: lecture.duration,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
