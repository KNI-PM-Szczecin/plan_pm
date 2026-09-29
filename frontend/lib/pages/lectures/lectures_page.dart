// Strona planu zajęć (makieta 2c) — nagłówek z datą i wyborem dnia, licznik
// i lista zajęć z bazy lokalnej. Karty zajęć ([Lecture]) są bez zmian.
// Logika dat startowych i narzędzia wydzielone do [lecture_utils.dart].
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/app_state_card.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';
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
  int currentWeekDay = DateTime.now().weekday - 1;

  DateTime now = DateTime.now();
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    // Wykładowca nie ma trybu zaocznego — używamy logiki stacjonarnej (pomijamy tylko weekend).
    final mode = AppModeManager.current == AppMode.lecturer
        ? StudyMode.stationary
        : Student.studyMode;
    currentDate = adjustInitialDate(mode, now);
  }

  late int selectedDay = currentDate.weekday - 1;

  /// Kierunek ostatniej zmiany daty (1 = później, -1 = wcześniej) — w tę
  /// stronę przesuwa się lista przy zmianie dnia lub tygodnia.
  int _direction = 1;

  static const _animationDuration = Duration(milliseconds: 260);

  Widget _slide(Widget child, Animation<double> animation, Key currentKey) {
    final incoming = child.key == currentKey;
    final dx = (incoming ? _direction : -_direction) * 0.12;
    return SlideTransition(
      position: Tween(
        begin: Offset(dx, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final databaseService = DatabaseService.instance;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          child: DaySelection(
            currentDate: currentDate,
            defaultSelected: selectedDay,
            onChange: (newDay, selectedDate) {
              setState(() {
                if (!DateUtils.isSameDay(selectedDate, currentDate)) {
                  _direction = selectedDate.isAfter(currentDate) ? 1 : -1;
                }
                selectedDay = newDay;
                currentDate = selectedDate;
              });
            },
          ),
        ),
        FutureBuilder<List<LectureModel>>(
          future: databaseService.fetchLectures(),
          builder: (context, snapshot) {
            final Widget content;
            final Key contentKey;
            if (snapshot.hasError) {
              contentKey = const ValueKey('error');
              content = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppStateCard(
                  icon: LucideIcons.bug,
                  title: l10n.unexpectedError,
                  message: snapshot.error.toString(),
                ),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              contentKey = const ValueKey('loading');
              content = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppStateCard.loading(title: l10n.lectureLoading),
              );
            } else {
              // Klucz = wybrany dzień: odświeżenie danych tego samego dnia nie
              // animuje, zmiana dnia/tygodnia — tak.
              contentKey = ValueKey(DateUtils.dateOnly(currentDate));
              content = _buildDay(context, l10n, snapshot);
            }

            return Expanded(
              child: AnimatedSwitcher(
                duration: _animationDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) =>
                    _slide(child, animation, contentKey),
                child: KeyedSubtree(key: contentKey, child: content),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Zajęcia wybranego dnia: licznik i lista kart albo pusty stan.
  Widget _buildDay(
    BuildContext context,
    AppLocalizations l10n,
    AsyncSnapshot<List<LectureModel>> snapshot,
  ) {
    final unfilteredLectures = snapshot.data ?? [];

    final lectures = unfilteredLectures.where((lecture) {
      final lectureDate = lecture.date;
      return lectureDate.year == currentDate.year &&
          lectureDate.month == currentDate.month &&
          lectureDate.day == currentDate.day;
    }).toList();

    if (lectures.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppStateCard(
          icon: LucideIcons.calendarX,
          title: l10n.todayDataNaN,
          message: l10n.lectureWigetHint,
        ),
      );
    }

    final countLabel = l10n.lectureLength(lectures.length);
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            // Licznik jako nagłówek sekcji — jak [AppSection]: wersaliki
            // na iOS, zdanie w akcencie na Androidzie.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isApplePlatform ? countLabel.toUpperCase() : countLabel,
                style: isApplePlatform
                    ? AppTextStyle.footnote.copyWith(
                        color: AppColor.labelSecondary,
                      )
                    : AppTextStyle.footnoteEmphasized.copyWith(
                        color: AppColor.primary,
                      ),
              ),
            ),
            Expanded(
              child: Skeletonizer(
                effect: const ShimmerEffect(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                enabled: snapshot.connectionState == ConnectionState.waiting,
                child: ListView.separated(
                  padding: EdgeInsets.only(
                    bottom:
                        kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: lectures.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return Lecture(
                      idx: index,
                      isProgressable: DateUtils.isSameDay(
                        lecture.date,
                        DateTime.now(),
                      ),
                      name: lecture.name,
                      timeFrom: lecture.startTime,
                      timeTo: lecture.endTime,
                      location: lecture.location,
                      professor: lecture.professor,
                      group: lecture.group,
                      duration: lecture.duration,
                      programName: lecture.programName,
                      year: lecture.year,
                      degreeLevel: lecture.degreeLevel,
                      notes: lecture.notes,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
