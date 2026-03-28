import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/extensions.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

List<String> daysShort = [];

int daysForward(StudyMode? mode, int weekday, bool sevenDay) {
  if (sevenDay) return 1;
  if (mode == StudyMode.stationary && weekday == DateTime.friday) return 3;
  if (mode == StudyMode.notStationary && weekday == DateTime.sunday) return 5;
  return 1;
}

int daysBackward(StudyMode? mode, int weekday, bool sevenDay) {
  if (sevenDay && weekday == DateTime.monday) return 6;
  if (sevenDay) return 1;
  if (mode == StudyMode.stationary && weekday == DateTime.monday) return 3;
  if (mode == StudyMode.notStationary && weekday == DateTime.friday) return 5;
  return 1;
}

List<int> visibleDayIndices(StudyMode? mode, bool sevenDay) {
  if (sevenDay) return List.generate(7, (i) => i);
  if (mode == StudyMode.notStationary) return List.generate(3, (i) => i + 4);
  return List.generate(5, (i) => i);
}

List<LinearGradient> softHorizontalGradients = [
  LinearGradient(
    // Gradient 1: od 0% do ~14.28%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3B82F6), Color(0xFF4C75F6)], // #3B82F6 -> #4C75F6
  ),
  LinearGradient(
    // Gradient 2: od ~14.28% do ~28.57%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4C75F6), Color(0xFF5D68F5)], // #4C75F6 -> #5D68F5
  ),
  LinearGradient(
    // Gradient 3: od ~28.57% do ~42.85%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5D68F5), Color(0xFF6E5CF5)], // #5D68F5 -> #6E5CF5
  ),
  LinearGradient(
    // Gradient 4: od ~42.85% do ~57.14%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6E5CF5), Color(0xFF7E4FF5)], // #6E5CF5 -> #7E4FF5
  ),
  LinearGradient(
    // Gradient 5: od ~57.14% do ~71.42%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7E4FF5), Color(0xFF8F42F5)], // #7E4FF5 -> #8F42F5
  ),
  LinearGradient(
    // Gradient 6: od ~71.42% do ~85.71%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8F42F5), Color(0xFFA035F5)], // #8F42F5 -> #A035F5
  ),
  LinearGradient(
    // Gradient 7: od ~85.71% do 100%
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFA035F5),
      Color(0xFF8B5CF6),
    ], // #A035F5 -> #8B5CF6 (końcowy kolor oryginalny)
  ),
];

class DaySelection extends StatefulWidget {
  const DaySelection({
    super.key,
    required this.currentDate,
    required this.onChange,
    required this.defaultSelected,
  });

  final Function(int selectedDay, DateTime selectedDate) onChange;
  final int defaultSelected;
  final DateTime currentDate;

  @override
  State<DaySelection> createState() => _DaySelectionState();
}

class _DaySelectionState extends State<DaySelection> {
  late DateTime currentDate = widget.currentDate;

  late int selectedDay = widget.defaultSelected;

  DateTime getDateFromIndex(DateTime date, int index) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final dateFromIndex = weekStart.add(Duration(days: index));
    return dateFromIndex;
  }

  @override
  void initState() {
    super.initState();
    sevenDayModeNotifier.addListener(onModeChange);
  }

  @override
  void dispose() {
    sevenDayModeNotifier.removeListener(onModeChange);
    super.dispose();
  }

  void onModeChange() {
    setState(() {
      final indices = visibleDayIndices(
        Student.studyMode,
        sevenDayModeNotifier.value,
      );
      if (!indices.contains(selectedDay)) {
        selectedDay = indices.reduce(
          (a, b) => (a - selectedDay).abs() <= (b - selectedDay).abs() ? a : b,
        );
        currentDate = getDateFromIndex(currentDate, selectedDay);
        widget.onChange(selectedDay, currentDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    daysShort = [
      l10n.daysShortMon,
      l10n.daysShortTue,
      l10n.daysShortWed,
      l10n.daysShortThu,
      l10n.daysShortFri,
      l10n.daysShortSat,
      l10n.daysShortSun,
    ];
    return Column(
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    currentDate = currentDate.subtract(
                      Duration(
                        days: daysBackward(
                          Student.studyMode,
                          currentDate.weekday,
                          sevenDayModeNotifier.value,
                        ),
                      ),
                    );
                    selectedDay = currentDate.weekday - 1;
                    widget.onChange(selectedDay, currentDate);
                  });
                },
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: AppColor.onBackgroundVariant,
                ),
              ),
              Text(
                "${currentDate.day} ${l10n.dateDayMonth(currentDate).toCapitalized}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColor.onBackground,
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    currentDate = currentDate.add(
                      Duration(
                        days: daysForward(
                          Student.studyMode,
                          currentDate.weekday,
                          sevenDayModeNotifier.value,
                        ),
                      ),
                    );
                    selectedDay = currentDate.weekday - 1;
                    widget.onChange(selectedDay, currentDate);
                  });
                },
                icon: Icon(
                  LucideIcons.chevronRight,
                  color: AppColor.onBackgroundVariant,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<EventColorStyle>(
          valueListenable: eventColorStyleNotifier,
          builder: (context, style, _) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.outline),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: AppColor.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    visibleDayIndices(
                      Student.studyMode,
                      sevenDayModeNotifier.value,
                    ).map((index) {
                      final isSelected = index == selectedDay;
                      final selectedBgColor =
                          style == EventColorStyle.monochrome
                          ? AppColor.primary
                          : softHorizontalGradients[index].colors.first;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedBgColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: isSelected
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        selectedDay = index;
                                        currentDate = getDateFromIndex(
                                          currentDate,
                                          index,
                                        );
                                        widget.onChange(
                                          selectedDay,
                                          currentDate,
                                        );
                                      });
                                    },
                              child: Container(
                                alignment: Alignment.center,
                                height: 40,
                                child: Text(
                                  daysShort[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColor.onPrimary
                                        : AppColor.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
