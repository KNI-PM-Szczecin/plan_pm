// Funkcje pomocnicze i stałe danych wspólne dla [LecturesPage], [Lecture] i [DaySelection].
// Zawiera: logikę dat startowych i nawigacji po dniach, formatowanie czasu trwania,
// skracanie grup oraz palety gradientów kart zajęć.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

// --- Daty i dni tygodnia ---

// Zwraca datę startową dla widoku planu: dla stacjonarnych pomija weekend,
// dla niestacjonarnych skacze do najbliższego piątku.
DateTime adjustInitialDate(StudyMode? mode, DateTime now) {
  if (mode == StudyMode.stationary) {
    if (now.weekday == DateTime.saturday) {
      return now.add(const Duration(days: 2));
    }
    if (now.weekday == DateTime.sunday) return now.add(const Duration(days: 1));
    return now;
  }
  if (now.weekday < DateTime.friday) {
    return now.add(Duration(days: DateTime.friday - now.weekday));
  }
  return now;
}

// Liczba dni do przodu przy nawigacji — omija weekend (stacjonarne) lub cały tydzień (niestacjonarne).
int daysForward(StudyMode? mode, int weekday, bool sevenDay) {
  if (sevenDay) return 1;
  if (mode == StudyMode.stationary && weekday == DateTime.friday) return 3;
  if (mode == StudyMode.notStationary && weekday == DateTime.sunday) return 5;
  return 1;
}

// Liczba dni wstecz przy nawigacji — omija weekend (stacjonarne) lub cały tydzień (niestacjonarne).
int daysBackward(StudyMode? mode, int weekday, bool sevenDay) {
  if (sevenDay) return 1;
  if (mode == StudyMode.stationary && weekday == DateTime.monday) return 3;
  if (mode == StudyMode.notStationary && weekday == DateTime.friday) return 5;
  return 1;
}

// Indeksy dni widocznych w selekcji: pon–pt dla stacjonarnych, pt–nd dla niestacjonarnych, cały tydzień w trybie 7-dniowym.
List<int> visibleDayIndices(StudyMode? mode, bool sevenDay) {
  if (sevenDay) return List.generate(7, (i) => i);
  if (mode == StudyMode.notStationary) return List.generate(3, (i) => i + 4);
  return List.generate(5, (i) => i);
}

// --- Postęp zajęć ---

// Zwraca postęp (0.0–1.0) i stan trwania dla zajęć o podanych godzinach.
// Czysta funkcja — nie ma efektów ubocznych, łatwa do testowania.
({double progress, bool isInProgress}) computeLectureProgress(
  String timeFrom,
  String timeTo,
  DateTime now,
) {
  DateTime parseTime(String time) {
    final parts = time.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  final start = parseTime(timeFrom);
  final end = parseTime(timeTo);

  if (now.isBefore(start)) return (progress: 0.0, isInProgress: false);
  if (now.isAfter(end)) return (progress: 1.0, isInProgress: false);

  final total = end.difference(start).inMinutes;
  if (total <= 0) return (progress: 0.0, isInProgress: false);

  final elapsed = now.difference(start).inMinutes;
  return (progress: (elapsed / total).clamp(0.0, 1.0), isInProgress: true);
}

// --- Formatowanie ---

// Parsuje string "X min" i formatuje jako "Xh Ymin" lub "Y min".
// Jeśli format nieznany, zwraca oryginalny string.
String formatDuration(String raw, AppLocalizations l10n) {
  final match = RegExp(r'^(\d+)\s*min$').firstMatch(raw.trim());
  if (match == null) return raw;
  final total = int.parse(match.group(1)!);
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours > 0) return l10n.durationHoursMinutes(hours, minutes);
  return l10n.durationMinutes(minutes);
}

// Skraca pełną sygnaturę grupy do kodu przed pierwszym "/" i deduplikuje.
// "L01/WI-S-AI-N/2024" → "L01", "L01,L02" → "L01, L02".
String longToShort(String long) {
  final codes = <String>[];
  for (final piece in long.split(',')) {
    final code = piece.split('/').first.trim();
    if (code.isEmpty || codes.contains(code)) continue;
    codes.add(code);
  }
  return codes.join(', ');
}

// Krótkie nazwy dni tygodnia — wypełniane przez DaySelection z kontekstu lokalizacji.
List<String> daysShort = [];

// --- Palety gradientów kart zajęć ---
// Indeks zajęcia % długość listy → deterministyczny kolor.

List<LinearGradient> defaultGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF6EE7B7), Color(0xFF3B82F6)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFB7185), Color(0xFFFACC15)],
  ),
];

List<LinearGradient> pastelGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF93C5FD), Color(0xFFC4B5FD)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF5EEAD4), Color(0xFF67E8F9)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFCD34D), Color(0xFFFCA5A5)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF9A8D4), Color(0xFFC4B5FD)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFDA4AF), Color(0xFFFDBA74)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF86EFAC), Color(0xFF93C5FD)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFD8B4FE), Color(0xFFA5B4FC)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFDA4AF), Color(0xFFFDE047)],
  ),
];

List<LinearGradient> vibrantGradients = [
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF2563EB), Color(0xFF7E22CE)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFD97706), Color(0xFFDC2626)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFDB2777), Color(0xFF7E22CE)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFE11D48), Color(0xFFEA580C)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF059669), Color(0xFF2563EB)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF9333EA), Color(0xFF4F46E5)],
  ),
  LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFE11D48), Color(0xFFCA8A04)],
  ),
];

// Płynne gradienty poziome dla pasków wyboru dnia — każdy kafelek dostaje fragment przejścia blue→purple.
List<LinearGradient> softHorizontalGradients = [
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3B82F6), Color(0xFF4C75F6)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4C75F6), Color(0xFF5D68F5)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5D68F5), Color(0xFF6E5CF5)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6E5CF5), Color(0xFF7E4FF5)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7E4FF5), Color(0xFF8F42F5)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8F42F5), Color(0xFFA035F5)],
  ),
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA035F5), Color(0xFF8B5CF6)],
  ),
];
