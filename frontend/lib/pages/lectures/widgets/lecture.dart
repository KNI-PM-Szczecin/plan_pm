// Karta pojedynczego zajęcia na liście planu.
// Obsługuje rozwijanie szczegółów oraz animowany pasek postępu dla zajęć aktualnie trwających.
// Gradienty, formatowanie czasu i skracanie grup wydzielone do [lecture_utils.dart].
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';
import 'package:plan_pm/pages/lectures/widgets/description_item.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lectures/utils/diagonal_stripes_painter.dart';
import 'package:plan_pm/pages/lectures/utils/canceled_reason.dart';

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
  // Jak pozostałe karty aplikacji (NewsCard.radius) — jeden promień na obu platformach.
  static const double _cardRadius = 22;
  static const Duration _expandDuration = Duration(milliseconds: 250);

  bool expanded = false;
  double _progress = 0.0; // 0.0–1.0, wypełnienie paska postępu
  bool _isInProgress = false; // czy zajęcia aktualnie trwają
  Timer? _timer;

  CanceledReason? canceledReason;
  bool get isCanceledOrRector => canceledReason != null || kDebugRectorHours;

  @override
  void initState() {
    super.initState();
    _determineStatus();

    if (widget.isProgressable && !isCanceledOrRector) {
      _computeProgress();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) setState(_computeProgress);
      });
    }
  }

  @override
  void didUpdateWidget(covariant Lecture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes ||
        oldWidget.timeFrom != widget.timeFrom ||
        oldWidget.timeTo != widget.timeTo ||
        oldWidget.isProgressable != widget.isProgressable) {
      _timer?.cancel();
      _timer = null;
      _determineStatus();
      _computeProgress();
      if (widget.isProgressable && !isCanceledOrRector && _progress < 1.0) {
        _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
          if (mounted) setState(_computeProgress);
        });
      }
    }
  }

  void _determineStatus() {
    canceledReason = canceledReasonFromNotes(widget.notes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Pobiera wynik z czystej funkcji i zapisuje do stanu widgetu.
  // Wywołana bezpośrednio (initState) lub wewnątrz setState (timer).
  void _computeProgress() {
    final r = computeLectureProgress(
      widget.timeFrom,
      widget.timeTo,
      DateTime.now(),
    );
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
    if (isCanceledOrRector) {
      cardGradient = null;
      cardColor = AppColor.rectorHoursBackground(Theme.of(context).brightness);
      textColor = isDarkMode
          ? AppColor.onPrimary.withValues(alpha: 0.7)
          : AppColor.onPrimary;
    }

    // Kolory pochodne od koloru tekstu — na pastelu (ciemny tekst) ciemnieją
    // razem z nim, zamiast zostawać białe na jasnym tle.
    final bool darkText = textColor.computeLuminance() < 0.5;
    final Color secondaryTextColor = textColor.withValues(alpha: 0.7);
    final Color separatorColor = textColor.withValues(alpha: 0.2);
    final Color trackColor = darkText
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.25);
    final Color detailsBoxColor = darkText
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.28);

    bool isInProgress =
        widget.isProgressable &&
        _isInProgress &&
        _progress > 0.0 &&
        _progress < 1.0 &&
        !isCanceledOrRector;

    String getBadgeText() {
      if (kDebugRectorHours && canceledReason == null) {
        return l10n.rectorHoursBadge; // Fallback dla debuga
      }

      switch (canceledReason) {
        case CanceledReason.rectorHours:
          return l10n.rectorHoursBadge; // Np. "Godziny rektorskie"
        case CanceledReason.rectorDay:
          return l10n.rectorDayBadge; // Np. "Dzień rektorski"
        case CanceledReason.canceled:
          return l10n.canceledClassBadge; // Np. "Zajęcia odwołane"
        default:
          return '';
      }
    }

    // Stała grubość — trwające zajęcia wyróżnia pasek postępu. Pogrubianie
    // poszerzało tekst i potrafiło przerzucić tytuł do nowej linii.
    const FontWeight titleWeight = FontWeight.bold;
    const FontWeight subTextWeight = FontWeight.normal;

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
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 0.5,
              )
            : null,
      ),
      child: ClipRRect(
        // ClipRRect, żeby paski nie wychodziły poza zaokrąglone rogi
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Stack(
          children: [
            // --- TŁO Z PASKAMI DLA GODZIN REKTORSKICH ---
            if (isCanceledOrRector)
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
                              if (isCanceledOrRector)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor
                                          .rectorHoursBadge, // Półprzezroczyste tło pastylki
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.info,
                                          size: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          getBadgeText(),
                                          style: AppTextStyle.caption1.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontWeight: AppTextWeight.semibold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Wiersz: nazwa zajęć + strzałka rozwijania
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.name,
                                      style: AppTextStyle.title3Emphasized.copyWith(
                                        fontWeight: titleWeight,
                                        // Automatycznie przyjmie biały dla zwykłych, a szarawy dla rektorskich
                                        color: textColor,
                                        // Tylko to wymaga warunku:
                                        decoration: isCanceledOrRector
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: textColor,
                                        decorationThickness: 2.0,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: expanded ? 0.5 : 0.0,
                                    duration: _expandDuration,
                                    curve: Curves.easeInOut,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        LucideIcons.chevronDown,
                                        size: 20,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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
                                    "${widget.timeFrom}–${widget.timeTo}",
                                    // Cyfry o stałej szerokości — godziny
                                    // kolejnych kart równają się w pionie.
                                    style: AppTextStyle.subheadline.copyWith(
                                      color: textColor,
                                      fontWeight: subTextWeight,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
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
                                      widget.location?.replaceAll(
                                            " , ",
                                            ", ",
                                          ) ??
                                          l10n.roomNaN,
                                      style: AppTextStyle.subheadline.copyWith(
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
                                Container(color: trackColor),
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
                      duration: _expandDuration,
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
                                  Divider(color: separatorColor),
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
                                          style: AppTextStyle.subheadline.copyWith(
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
                                    // Typografia jak nagłówek [AppSection]:
                                    // wersaliki na iOS, zdanie na Androidzie.
                                    child: Text(
                                      isApplePlatform
                                          ? l10n.additionalInformation
                                                .toUpperCase()
                                          : l10n.additionalInformation,
                                      style:
                                          (isApplePlatform
                                                  ? AppTextStyle.footnote
                                                  : AppTextStyle
                                                        .footnoteEmphasized)
                                              .copyWith(
                                                color: secondaryTextColor,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Ramka z pozostałymi szczegółami zajęcia
                                  Container(
                                    decoration: BoxDecoration(
                                      color: detailsBoxColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child:
                                        AppModeManager.current ==
                                            AppMode.lecturer
                                        ? Column(
                                            children: [
                                              DescriptionItem(
                                                icon: LucideIcons.users,
                                                color: AppColor.systemGreen,
                                                textColor: textColor,
                                                name: l10n.groupLabel,
                                                content: longToShort(
                                                  widget.group,
                                                ),
                                              ),
                                              if (widget.year != null)
                                                DescriptionItem(
                                                  icon:
                                                      LucideIcons.graduationCap,
                                                  color: AppColor.systemBlue,
                                                textColor: textColor,
                                                  name: l10n.yearLabel,
                                                  content: l10n.studyYear(
                                                    widget.year!,
                                                  ),
                                                ),
                                              if (widget.degreeLevel != null)
                                                DescriptionItem(
                                                  icon: LucideIcons.award,
                                                  color: AppColor.systemOrange,
                                                textColor: textColor,
                                                  name: l10n.degreeLevelLabel,
                                                  content: widget.degreeLevel!,
                                                ),
                                              if (widget.programName != null)
                                                DescriptionItem(
                                                  icon: LucideIcons.bookOpen,
                                                  color: AppColor.systemPurple,
                                                textColor: textColor,
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
                                                  color: AppColor.systemBlue,
                                                textColor: textColor,
                                                  name: l10n.professorLabel,
                                                  content:
                                                      widget.professor ??
                                                      l10n.professorNaN,
                                                ),
                                              DescriptionItem(
                                                icon: LucideIcons.bookLock,
                                                color: AppColor.systemGreen,
                                                textColor: textColor,
                                                name: l10n.groupLabel,
                                                content: longToShort(
                                                  widget.group,
                                                ),
                                              ),
                                              if (widget.notes != null &&
                                                  !isCanceledOrRector)
                                                DescriptionItem(
                                                  icon: LucideIcons.stickyNote,
                                                  color: AppColor.systemYellow,
                                                textColor: textColor,
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

    // Bez własnego marginesu — odstępy między kartami ustawia lista.
    return ClipRRect(
      borderRadius: BorderRadius.circular(_cardRadius),
      child: isIOS
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: cardContainer,
            )
          : cardContainer,
    );
  }
}
