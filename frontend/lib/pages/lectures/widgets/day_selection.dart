// Pasek wyboru dnia tygodnia z nawigacją strzałkami i podświetleniem aktywnego dnia.
// Reaguje na zmianę trybu 7-dniowego przez [sevenDayModeNotifier].
// Logika nawigacji i gradienty wydzielone do [lecture_utils.dart].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/utils/extensions.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

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

  // Wywoływana gdy zmienia się tryb 7-dniowy. Jeśli aktualnie wybrany dzień
  // znika z paska (np. sobota po wyłączeniu trybu 7-dniowego), przeskakuje
  // do najbliższego dostępnego dnia metodą reduce z abs() — szukanie sąsiada.
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
