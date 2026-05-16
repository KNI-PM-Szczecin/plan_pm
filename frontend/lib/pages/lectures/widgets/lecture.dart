// Karta pojedynczego zajęcia na liście planu.
// Obsługuje rozwijanie szczegółów oraz animowany pasek postępu dla zajęć aktualnie trwających.
// Gradienty, formatowanie czasu i skracanie grup wydzielone do [lecture_utils.dart].
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';
import 'package:plan_pm/pages/lectures/widgets/description_item.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lectures/utils/diagonal_stripes_painter.dart';

import '../../../env_config.dart';

// Karta pojedynczego zajęcia na liście planu.
// Obsługuje rozwijanie szczegółów oraz animowany pasek postępu dla zajęć aktualnie trwających.
class Lecture extends StatefulWidget {
  const Lecture({
    super.key,
    required this.idx, // pozycja na liście — decyduje o kolorze gradientu
    required this.name,
    required this.timeFrom,
    required this.timeTo,
    this.location,
    this.professor,
    required this.group,
    required this.duration,
    this.notes,
    this.isProgressable = false, // true tylko dla zajęć z dzisiejszego dnia
    this.programName,
    this.year,
    this.degreeLevel,
  });

  final int idx;
  final String name;
  final String timeFrom;
  final String timeTo;
  final String? location;
  final String? professor;
  final String group;
  final String duration;
  final String? notes;
  final bool isProgressable;
  final String? programName;
  final int? year;
  final String? degreeLevel;

  @override
  State<Lecture> createState() => _LectureState();
}

class _LectureState extends State<Lecture> {
  bool expanded = false;
  double _progress = 0.0; // 0.0–1.0, wypełnienie paska postępu
  bool _isInProgress = false; // czy zajęcia aktualnie trwają
  Timer? _timer;
  late bool isRectorHours;

  @override
  void initState() {
    super.initState();

    isRectorHours = kDebugRectorHours || widget.notes?.toLowerCase().contains('godziny rektorskie') ?? false;

    if (widget.isProgressable && !isRectorHours) {
      // Ustaw wartości bezpośrednio przed pierwszym buildem — setState w initState
      // nie gwarantuje przebudowy w każdej wersji Fluttera.
      _computeProgress();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) setState(_computeProgress);
      });
    }
  }

  @override
  void didUpdateWidget(covariant Lecture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      isRectorHours = kDebugRectorHours || (widget.notes?.toLowerCase().contains('godziny rektorskie') ?? false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Pobiera wynik z czystej funkcji i zapisuje do stanu widgetu.
  // Wywołana bezpośrednio (initState) lub wewnątrz setState (timer).
  void _computeProgress() {
    final r = computeLectureProgress(widget.timeFrom, widget.timeTo, DateTime.now());
    _progress = r.progress;
    _isInProgress = r.isInProgress;
    if (_progress >= 1.0) _timer?.cancel();
  }

  void switchExpanded() {
    setState(() {
      HapticFeedback.lightImpact();
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dobierz gradient/kolor i kolor tekstu na podstawie ustawienia stylu kolorów.
    // Pastel używa ciemnego tekstu bo jasne tło słabo kontrastuje z białym.
    final style = eventColorStyleNotifier.value;
    LinearGradient? cardGradient;
    Color? cardColor;
    Color textColor = AppColor.onPrimary;
    Color progressBarFillColor = Colors.white.withValues(alpha: 0.85);

    switch (style) {
      case EventColorStyle.monochrome:
        cardColor = AppColor.primary;
      case EventColorStyle.pastel:
        cardGradient = pastelGradients[widget.idx % pastelGradients.length];
        textColor = Colors.black87;
        progressBarFillColor = textColor.withValues(alpha: 0.50);
      case EventColorStyle.vibrant:
        cardGradient = vibrantGradients[widget.idx % vibrantGradients.length];
      default:
        cardGradient = defaultGradients[widget.idx % defaultGradients.length];
    }

    // Detekcja godzin rektorskich i nadpisanie kolorów na szaro
    if (isRectorHours) {
      cardGradient = null;
      cardColor = AppColor.rectorHoursBackground(Theme.of(context).brightness);
      textColor = isDarkMode ? AppColor.onPrimary.withValues(alpha: 0.7) : AppColor.onPrimary;
    }

    bool isInProgress = widget.isProgressable && _isInProgress && _progress > 0.0 && _progress < 1.0 && !isRectorHours;

    // Zajęcia aktualnie trwające są wizualnie wyróżnione pogrubieniem
    FontWeight titleWeight = isInProgress ? FontWeight.w800 : FontWeight.bold;
    FontWeight subTextWeight = isInProgress ? FontWeight.bold : FontWeight.normal;

    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    // iOS glass: tinted semi-transparent gradient + backdrop blur + specular border
    final LinearGradient? iosGradient = isIOS && cardGradient != null
        ? LinearGradient(
            begin: cardGradient.begin,
            end: cardGradient.end,
            colors: cardGradient.colors
                .map((c) => c.withValues(alpha: 0.90))
                .toList(),
          )
        : null;
    final Color? iosColor = isIOS ? cardColor?.withValues(alpha: 0.90) : null;

    final cardContainer = Container(
      decoration: BoxDecoration(
        gradient: isIOS ? iosGradient : cardGradient,
        color: isIOS ? iosColor : cardColor,
        border: isIOS
            ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.5)
            : null,
      ),
      child: ClipRRect( // ClipRRect, żeby paski nie wychodziły poza zaokrąglone rogi
        borderRadius: BorderRadius.circular(isIOS ? 16 : 12),
        child: Stack(
          children: [
            // --- TŁO Z PASKAMI DLA GODZIN REKTORSKICH ---
            if (isRectorHours)
              Positioned.fill(
                child: CustomPaint(
                  painter: DiagonalStripesPainter(
                    color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.03) 
                      : Colors.black.withValues(alpha: 0.05),
                    stripeWidth: 1.5,
                    spacing: 12.0,
                  ),
                ),
              ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              radius: 300.0,
              onTap: switchExpanded,
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Column(
                children: [
                  // Górna część — tytuł, godzina, sala + opcjonalny pasek postępu
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pastylka "Godziny rektorskie" nad tytułem zajęć — tylko dla zajęć z wykrytymi godzinami rektorskimi
                            if (isRectorHours)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColor.rectorHoursBadge, // Półprzezroczyste tło pastylki
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.info, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.rectorHoursBadge,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            // Wiersz: nazwa zajęć + strzałka rozwijania
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.name,
                                    style: TextStyle(
                                      fontWeight: titleWeight,
                                      fontSize: 20,
                                      // Automatycznie przyjmie biały dla zwykłych, a szarawy dla rektorskich
                                      color: textColor, 
                                      // Tylko to wymaga warunku:
                                      decoration: isRectorHours ? TextDecoration.lineThrough : null,
                                      decorationColor: textColor,
                                      decorationThickness: 2.0,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: expanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.easeInOut,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      LucideIcons.chevronDown,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Wiersz: godzina + sala
                            Row(
                              spacing: 5,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 16,
                                  color: textColor,
                                ),
                                Text(
                                  "${widget.timeFrom} - ${widget.timeTo}",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: subTextWeight,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: textColor,
                                ),
                                // Sala — separator z bazy to " , " (spacja-przecinek-spacja),
                                // normalizowany do standardowego ", "
                                Expanded(
                                  child: Text(
                                    widget.location?.replaceAll(" , ", ", ") ?? l10n.roomNaN,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: subTextWeight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Pasek postępu na dole górnej sekcji — widoczny tylko gdy zajęcia trwają
                      if (isInProgress)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 5,
                          child: Stack(
                            children: [
                              // Tło paska (półprzezroczyste)
                              Container(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              // Wypełnienie paska animowane przy każdej zmianie _progress
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: _progress,
                                  ),
                                  builder: (context, value, child) {
                                    return FractionallySizedBox(
                                      widthFactor: value,
                                      child: Container(
                                        color: progressBarFillColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Rozwijana sekcja szczegółów
                  AnimatedSize(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    child: expanded
                        ? Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                              left: 12,
                              right: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(
                                  color: Color.fromARGB(80, 228, 227, 227),
                                ),
                                const SizedBox(height: 2),
                                // left: 4 wyrównuje ikonę do lewej krawędzi górnej sekcji (padding 16 vs 12)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 16,
                                        color: textColor,
                                      ),
                                      Text(
                                        "${l10n.lengthLabel}: ${formatDuration(widget.duration, l10n)}",
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: subTextWeight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Nagłówek sekcji dodatkowych szczegółów
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    l10n.additionalInformation,
                                    style: const TextStyle(
                                      color: Color(0xB3FFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Ramka z pozostałymi szczegółami zajęcia
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      AppModeManager.current == AppMode.lecturer
                                      ? Column(
                                          children: [
                                            DescriptionItem(
                                              icon: LucideIcons.users,
                                              color: Colors.green,
                                              name: l10n.groupLabel,
                                              content: longToShort(
                                                widget.group,
                                              ),
                                            ),
                                            if (widget.year != null)
                                              DescriptionItem(
                                                icon: LucideIcons.graduationCap,
                                                color: Colors.blue,
                                                name: l10n.yearLabel,
                                                content: l10n.studyYear(
                                                  widget.year!,
                                                ),
                                              ),
                                            if (widget.degreeLevel != null)
                                              DescriptionItem(
                                                icon: LucideIcons.award,
                                                color: Colors.orange,
                                                name: l10n.degreeLevelLabel,
                                                content: widget.degreeLevel!,
                                              ),
                                            if (widget.programName != null)
                                              DescriptionItem(
                                                icon: LucideIcons.bookOpen,
                                                color: Colors.purple,
                                                name: l10n.fieldLabel,
                                                content: widget.programName!,
                                              ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            if (widget.professor != null)
                                              DescriptionItem(
                                                icon: LucideIcons.user,
                                                color: Colors.blue,
                                                name: l10n.professorLabel,
                                                content:
                                                    widget.professor ??
                                                    l10n.professorNaN,
                                              ),
                                            DescriptionItem(
                                              icon: LucideIcons.bookLock,
                                              color: Colors.green,
                                              name: l10n.groupLabel,
                                              content: longToShort(
                                                widget.group,
                                              ),
                                            ),
                                            if (widget.notes != null && !isRectorHours)
                                              DescriptionItem(
                                                icon: LucideIcons.stickyNote,
                                                color: Colors.yellow,
                                                name: l10n.notesLabel,
                                                content:
                                                    widget.notes ??
                                                    l10n.emptyNotesLabel,
                                              ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
      

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isIOS ? 16 : 12),
        child: isIOS
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: cardContainer,
              )
            : cardContainer,
      ),
    );
  }
}
