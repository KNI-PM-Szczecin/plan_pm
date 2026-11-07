// Ekran wyboru grup trzyma wybór u siebie i oddaje go do
// `Student.selectedGroups` dopiero przy zapisie. Wcześniej każde tapnięcie
// (i samo wejście) nadpisywało stan w pamięci, więc po wyjściu „wstecz" bez
// zapisu ustawienia pokazywały niezapisane grupy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';

const _groups = [
  'A01/NAW/2025/2026 ZS',
  'A02/NAW/2025/2026 ZS',
  'L01/NAW/2025/2026 ZS',
  'L02/NAW/2025/2026 ZS',
];

Widget _app() => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GroupSelectionPage(loadGroups: () async => _groups),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
  });

  testWidgets('leaving without saving keeps the saved groups', (tester) async {
    Student.selectedGroups = ['A01/NAW/2025/2026 ZS'];

    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Ekran startuje od zera, ale nie rusza zapisanych grup.
    expect(Student.selectedGroups, ['A01/NAW/2025/2026 ZS']);

    await tester.tap(find.text('A02'));
    await tester.tap(find.text('Zaznacz wszystkie').last);
    await tester.pump();
    expect(find.text('Odznacz wszystkie'), findsOneWidget);
    expect(Student.selectedGroups, ['A01/NAW/2025/2026 ZS']);

    Navigator.of(tester.element(find.byType(GroupSelectionPage))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(GroupSelectionPage), findsNothing);
    expect(Student.selectedGroups, ['A01/NAW/2025/2026 ZS']);
  });
}
