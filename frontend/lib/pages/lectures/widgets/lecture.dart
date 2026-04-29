import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/app_mode.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/pages/lectures/widgets/description_item.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

// Palety gradientów dla kart zajęć — indeks zajęcia % długość listy = deterministyczny kolor.
// Trzy warianty odpowiadają ustawieniu EventColorStyle w notifierze.

List<LinearGradient> defaultGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // blue-500 → purple-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)], // teal-500 → cyan-500
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)], // amber-500 → red-500
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)], // pink-500 → purple-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB923C)], // rose-500 → orange-400
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF6EE7B7), Color(0xFF3B82F6)], // green-300 → blue-500
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)], // fuchsia-500 → indigo-500
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFB7185), Color(0xFFFACC15)], // red-400 → yellow-400
  ),
];

List<LinearGradient> pastelGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF93C5FD), Color(0xFFC4B5FD)], // blue-300 → purple-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF5EEAD4), Color(0xFF67E8F9)], // teal-300 → cyan-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFCD34D), Color(0xFFFCA5A5)], // amber-300 → red-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF9A8D4), Color(0xFFC4B5FD)], // pink-300 → purple-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFDA4AF), Color(0xFFFDBA74)], // rose-300 → orange-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF86EFAC), Color(0xFF93C5FD)], // green-300 → blue-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFD8B4FE), Color(0xFFA5B4FC)], // fuchsia-300 → indigo-300
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFDA4AF), Color(0xFFFDE047)], // red-300 → yellow-300
  ),
];

List<LinearGradient> vibrantGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF2563EB), Color(0xFF7E22CE)], // blue-600 → purple-700
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF0D9488), Color(0xFF0891B2)], // teal-600 → cyan-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFD97706), Color(0xFFDC2626)], // amber-600 → red-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFDB2777), Color(0xFF7E22CE)], // pink-600 → purple-700
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFE11D48), Color(0xFFEA580C)], // rose-600 → orange-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF059669), Color(0xFF2563EB)], // green-600 → blue-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF9333EA), Color(0xFF4F46E5)], // fuchsia-600 → indigo-600
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFE11D48), Color(0xFFCA8A04)], // red-600 → yellow-600
  ),
];

// Parsuje string "X min" z modelu i formatuje go jako "Xh Ymin" lub "Y min".
// Jeśli format jest nieznany, zwraca oryginalny string.
String formatDuration(String raw, AppLocalizations l10n) {
  final match = RegExp(r'^(\d+)\s*min$').firstMatch(raw.trim());
  if (match == null) return raw;
  final total = int.parse(match.group(1)!);
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours > 0) return l10n.durationHoursMinutes(hours, minutes);
  return l10n.durationMinutes(minutes);
}

// Skraca pełną nazwę grupy do pierwszego członu przed "/".
// Np. "WI-S-AI-N-1/WI-S-AI-N-2" → "WI-S-AI-N-1, WI-S-AI-N-2"
String longToShort(String long) {
  final pieces = long
      .split(",")
      .map((piece) => piece.split("/")[0])
      .toString()
      .replaceAll("(", "")
      .replaceAll(")", "");

  return pieces;
}

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

  @override
  void initState() {
    super.initState();

    if (widget.isProgressable) {
      // Ustaw wartości bezpośrednio przed pierwszym buildem — setState w initState
      // nie gwarantuje przebudowy w każdej wersji Fluttera.
      _computeProgress();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) setState(_computeProgress);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Aktualizuje _progress i _isInProgress. Wywoływana bezpośrednio (initState)
  // lub wewnątrz setState (timer) — nie wywołuje setState sama z siebie.
  void _computeProgress() {
    final now = DateTime.now();
    DateTime parseTime(String time) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final startTime = parseTime(widget.timeFrom);
    final endTime = parseTime(widget.timeTo);

    if (now.isBefore(startTime)) {
      _progress = 0.0;
      _isInProgress = false;
    } else if (now.isAfter(endTime)) {
      _progress = 1.0;
      _isInProgress = false;
      _timer?.cancel();
    } else {
      final totalMinutes = endTime.difference(startTime).inMinutes;
      final elapsedMinutes = now.difference(startTime).inMinutes;
      if (totalMinutes > 0) {
        _progress = (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
        _isInProgress = true;
      }
    }
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

    // Dobierz gradient/kolor i kolor tekstu na podstawie ustawienia stylu kolorów.
    // Pastel używa ciemnego tekstu bo jasne tło słabo kontrastuje z białym.
    final style = eventColorStyleNotifier.value;
    Gradient? cardGradient;
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

    bool isInProgress = widget.isProgressable && _isInProgress;

    // Zajęcia aktualnie trwające są wizualnie wyróżnione pogrubieniem
    FontWeight titleWeight = isInProgress ? FontWeight.w900 : FontWeight.bold;
    FontWeight subTextWeight = isInProgress
        ? FontWeight.bold
        : FontWeight.normal;

    // Jeden gradient obejmuje całą kartę (górna + rozwijana sekcja).
    // ClipRRect przycina całą kartę i ripple InkWell do zaokrąglonych rogów.
    // Jeden wspólny Material + InkWell — ripple maluje się na jednej powierzchni
    // przez całą wysokość karty, niezależnie od tego gdzie użytkownik tapnie.
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(gradient: cardGradient, color: cardColor),
          child: Material(
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
                          children: [
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
                                      color: textColor,
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
                                    widget.location != null
                                        ? widget.location!
                                                      .split(" , ")
                                                      .length ==
                                                  1
                                              ? widget.location!
                                              : widget.location!
                                                    .split(" , ")
                                                    .join(", ")
                                        : l10n.roomNaN,
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
                                            if (widget.notes != null)
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
        ),
      ),
    );
  }
}
