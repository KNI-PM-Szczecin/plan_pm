// Sprawdza na prawdziwym urządzeniu, że chevrony na ekranie "Classes"
// przesuwają plan o cały tydzień, a nie o jeden dzień.
//
// Testy jednostkowe (test/navigation_logic_test.dart) dowodzą, że nextWeek /
// previousWeek liczą dokładnie ±7 dni. Ten test dowodzi czegoś innego:
// że przyciski są do nich faktycznie podpięte i że UI się odświeża.
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/chevron_week_test.dart \
//     -d <simulator-udid>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';

import 'package:plan_pm/global/utils/extensions.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String readLabel(WidgetTester tester) {
    final finder = find.byKey(const ValueKey('daySelectionDate'));
    expect(finder, findsOneWidget, reason: 'nie znaleziono etykiety z datą');
    return (tester.widget<Text>(finder)).data!;
  }

  /// Etykieta ("24 Wrzesień", "2 October") -> pełna data.
  ///
  /// Etykieta nie ma roku, a nazwę miesiąca buduje l10n w języku aplikacji,
  /// więc tabelę miesięcy składamy TĄ SAMĄ funkcją co day_selection.dart, a rok
  /// bierzemy najbliższy [near]. Dzięki temu asercja o 7 dniach działa także
  /// przez granicę miesiąca i roku — wcześniej wtedy po cichu ją pomijaliśmy.
  DateTime readDate(WidgetTester tester, DateTime near) {
    final label = readLabel(tester).trim();
    final space = label.indexOf(' ');
    final day = int.parse(label.substring(0, space));
    final monthName = label.substring(space + 1);

    final context = tester.element(find.byKey(const ValueKey('daySelectionDate')));
    final l10n = AppLocalizations.of(context)!;
    final months = [
      for (var m = 1; m <= 12; m++) l10n.dateDayMonth(DateTime(2000, m)).toCapitalized,
    ];
    final month = months.indexOf(monthName) + 1;
    expect(month, isPositive, reason: 'nieznana nazwa miesiąca: "$monthName"');

    final candidates = [near.year - 1, near.year, near.year + 1]
        .map((y) => DateTime(y, month, day))
        .toList()
      ..sort((a, b) => a.difference(near).abs().compareTo(b.difference(near).abs()));
    return candidates.first;
  }

  testWidgets('chevrony przesuwają plan o tydzień', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    // Start robi splash + app_initialization (sieć, SQLite), więc pumpAndSettle
    // samo w sobie nie wystarcza — dajemy realny czas na dojście do home.
    await tester.pumpAndSettle(const Duration(seconds: 2));
    for (var i = 0; i < 20; i++) {
      if (find.byType(PreloadPageView).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Zakładka "Classes" to strona 1. Na iOS pasek zakładek jest natywnym
    // platform view, więc przechodzimy przesunięciem PageView.
    await tester.drag(find.byType(PreloadPageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    final before = readDate(tester, DateTime.now());
    await binding.takeScreenshot('01_classes_before');

    // Różnica w dniach kalendarzowych (UTC — zmiana czasu nie zjada godziny).
    int daysBetween(DateTime a, DateTime b) =>
        DateTime.utc(b.year, b.month, b.day)
            .difference(DateTime.utc(a.year, a.month, a.day))
            .inDays;

    // --- w przód ---
    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();
    final afterNext = readDate(tester, before);
    await binding.takeScreenshot('02_after_next_week');
    expect(daysBetween(before, afterNext), 7,
        reason: 'chevron w prawo: $before -> $afterNext, oczekiwano +7 dni');

    // --- w tył: powrót do punktu wyjścia ---
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(readDate(tester, before), before, reason: 'powrót nie wrócił do tej samej daty');

    // --- w tył jeszcze raz: tydzień przed startem ---
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    final afterPrev = readDate(tester, before);
    await binding.takeScreenshot('03_after_previous_week');
    expect(daysBetween(before, afterPrev), -7,
        reason: 'chevron w lewo: $before -> $afterPrev, oczekiwano -7 dni');
  });
}
