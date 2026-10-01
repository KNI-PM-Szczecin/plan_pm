import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/widgets/lecturer_search_field.dart';

Widget _app(TextEditingController controller, ValueChanged<String> onChanged) =>
    MaterialApp(
      locale: const Locale('pl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: LecturerSearchField(controller: controller, onChanged: onChanged),
      ),
    );

void main() {
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
  });

  testWidgets('clear button exposes a localized tap action and 48pt target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = TextEditingController(text: 'Adam');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(_app(controller, changes.add));
      await tester.pumpAndSettle();

      final button = find.byType(IconButton);
      final node = tester.getSemantics(button);
      final data = node.getSemanticsData();
      expect(data.tooltip, 'Wyczyść tekst');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(button), const Size(48, 48));

      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(changes, ['']);
      expect(find.byType(IconButton), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('clear appears after typing and works with Tab and Enter', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await tester.pumpWidget(_app(controller, changes.add));
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'Adam');
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(changes, ['Adam', '']);
    expect(find.byType(IconButton), findsNothing);
  });
}
