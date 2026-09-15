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

import 'package:plan_pm/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// "21 September" -> 21. Zwraca null, gdy etykieta nie zaczyna się liczbą.
  int? dayOf(String label) => int.tryParse(label.trim().split(' ').first);

  /// "21 September" -> "September"
  String monthOf(String label) {
    final parts = label.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  String readDate(WidgetTester tester) {
    final finder = find.byKey(const ValueKey('daySelectionDate'));
    expect(finder, findsOneWidget, reason: 'nie znaleziono etykiety z datą');
    return (tester.widget<Text>(finder)).data!;
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

    final before = readDate(tester);
    await binding.takeScreenshot('01_classes_before');

    // --- w przód ---
    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pumpAndSettle();
    final afterNext = readDate(tester);
    await binding.takeScreenshot('02_after_next_week');

    expect(afterNext, isNot(before), reason: 'data nie zmieniła się po kliknięciu');
    if (monthOf(before) == monthOf(afterNext)) {
      expect(
        dayOf(afterNext)! - dayOf(before)!,
        7,
        reason: 'chevron powinien przesunąć o 7 dni, nie o 1',
      );
    }

    // --- w tył: powrót do punktu wyjścia ---
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(readDate(tester), before, reason: 'powrót nie wrócił do tej samej daty');

    // --- w tył jeszcze raz: tydzień przed startem ---
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    final afterPrev = readDate(tester);
    await binding.takeScreenshot('03_after_previous_week');

    expect(afterPrev, isNot(before));
    if (monthOf(before) == monthOf(afterPrev)) {
      expect(dayOf(before)! - dayOf(afterPrev)!, 7);
    }
  });
}
