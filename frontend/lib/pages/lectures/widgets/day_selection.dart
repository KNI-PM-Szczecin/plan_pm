// Nagłówek planu zajęć (makieta 2c): data wybranego dnia z przyciskami
// poprzedni/następny tydzień, a pod nią pigułka z dniami tygodnia (skrót + numer).
// Reaguje na zmianę trybu 7-dniowego przez [sevenDayModeNotifier].
// Logika nawigacji wydzielona do [lecture_utils.dart]; karty zajęć ([Lecture])
// są poza tym widżetem i nie zależą od jego wyglądu.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/extensions.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
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

  /// Kierunek ostatniej zmiany tygodnia: 1 = następny, -1 = poprzedni.
  /// Steruje stroną, w którą przesuwają się dni w pigułce.
  int _direction = 1;

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

  void _changeWeek(DateTime Function(DateTime) shift, int direction) {
    HapticFeedback.selectionClick();
    setState(() {
      _direction = direction;
      currentDate = shift(currentDate);
      selectedDay = currentDate.weekday - 1;
      widget.onChange(selectedDay, currentDate);
    });
  }

  void _selectDay(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedDay = index;
      currentDate = getDateFromIndex(currentDate, index);
      widget.onChange(selectedDay, currentDate);
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
    // „Środa, 7 października" — wzorzec intl dla języka aplikacji (odmiana
    // miesiąca i kolejność dzień/miesiąc zależą od locale).
    final dateLabel = DateFormat.MMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(currentDate).toCapitalizedFirst;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: _animationDuration,
                  layoutBuilder: _leftAlignedLayout,
                  child: KeyedSubtree(
                    key: ValueKey(dateLabel),
                    child: Text(
                      key: const ValueKey('daySelectionDate'),
                      dateLabel,
                      style: AppTextStyle.subheadline.copyWith(
                        color: AppColor.labelSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              _WeekButton(
                icon: LucideIcons.chevronLeft,
                label: l10n.previousWeek,
                onTap: () => _changeWeek(previousWeek, -1),
              ),
              const SizedBox(width: 8),
              _WeekButton(
                icon: LucideIcons.chevronRight,
                label: l10n.nextWeek,
                onTap: () => _changeWeek(nextWeek, 1),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: ShapeDecoration(
            color: AppColor.fillTertiary,
            shape: const StadiumBorder(),
          ),
          // Zmiana tygodnia: stare dni wyjeżdżają w stronę przeciwną do strzałki,
          // nowe wjeżdżają z jej strony. Wybór dnia w obrębie tygodnia nie
          // zmienia klucza, więc animuje się tylko podświetlenie.
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedSwitcher(
              duration: _animationDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  _slide(child, animation, _weekKey, 0.35),
              child: Row(
                key: _weekKey,
                children: [
                  for (final index in visibleDayIndices(
                    Student.studyMode,
                    sevenDayModeNotifier.value,
                  ))
                    Expanded(
                      child: _DayCell(
                        // Jak przed redesignem: każdy dzień ma własny gradient,
                        // a styl „Jednokolorowe" zostaje przy kolorze akcentu.
                        gradient:
                            eventColorStyleNotifier.value ==
                                EventColorStyle.monochrome
                            ? LinearGradient(
                                colors: [AppColor.primary, AppColor.primary],
                              )
                            : softHorizontalGradients[index],
                        short: daysShort[index],
                        day: getDateFromIndex(currentDate, index).day,
                        selected: index == selectedDay,
                        onTap: () => _selectDay(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _animationDuration = Duration(milliseconds: 260);

  /// Klucz tygodnia (poniedziałek) — zmienia się tylko przy zmianie tygodnia.
  ValueKey<DateTime> get _weekKey =>
      ValueKey(DateUtils.dateOnly(getDateFromIndex(currentDate, 0)));

  /// Przesunięcie + przenikanie w kierunku [_direction]: nowy element wjeżdża
  /// z jednej strony, stary wyjeżdża w drugą ([AnimatedSwitcher] odtwarza
  /// animację wstecz dla wychodzącego, więc znak zależy od tego, który to).
  Widget _slide(
    Widget child,
    Animation<double> animation,
    Key currentKey,
    double distance,
  ) {
    final incoming = child.key == currentKey;
    final dx = (incoming ? _direction : -_direction) * distance;
    return SlideTransition(
      position: Tween(
        begin: Offset(dx, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  static Widget _leftAlignedLayout(Widget? current, List<Widget> previous) =>
      Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]);
}

/// Okrągły przycisk tygodnia: szare tło, chevron w akcencie.
class _WeekButton extends StatelessWidget {
  const _WeekButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AppPressable(
        color: AppColor.fillTertiary,
        shape: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(icon, size: 20, color: AppColor.primary),
        ),
      ),
    );
  }
}

/// Dzień w pigułce: skrót nad numerem. Wybrany dostaje gradient swojego dnia
/// tygodnia i biały tekst.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.gradient,
    required this.short,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final Gradient gradient;
  final String short;
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppPressable(
        shape: const StadiumBorder(),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: ShapeDecoration(
            gradient: selected ? gradient : null,
            shape: const StadiumBorder(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                short,
                style: AppTextStyle.caption1.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColor.labelSecondary,
                ),
              ),
              Text(
                '$day',
                style: AppTextStyle.subheadlineEmphasized.copyWith(
                  color: selected ? Colors.white : AppColor.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
