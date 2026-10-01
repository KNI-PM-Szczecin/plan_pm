import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_dialog.dart';
import 'package:plan_pm/global/widgets/whats_new_dialog.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

Widget _app(Widget dialog, double textScale) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      padding: const EdgeInsets.only(top: 24, bottom: 24),
    ),
    child: child!,
  ),
  home: Scaffold(body: dialog),
);

void main() {
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
  });

  for (final (size, scale) in [
    (const Size(320, 480), 1.0),
    (const Size(800, 360), 2.0),
  ]) {
    testWidgets('long dialog keeps both actions visible at $size / $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var primaryCalls = 0;
      var secondaryCalls = 0;
      await tester.pumpWidget(
        _app(
          AppDialog(
            icon: Icons.info,
            iconColor: Colors.blue,
            title: 'Długi komunikat',
            message: 'Opis komunikatu',
            content: Column(
              children: List.generate(50, (i) => Text('Wpis $i')),
            ),
            primaryLabel: 'Gotowe',
            onPrimary: () => primaryCalls++,
            secondaryLabel: 'Później',
            onSecondary: () => secondaryCalls++,
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final buttons = find.byType(AppButton);
      final before = tester.getRect(buttons.first);
      expect(before.top, greaterThanOrEqualTo(24));
      expect(
        tester.getRect(buttons.last).bottom,
        lessThanOrEqualTo(size.height - 24),
      );
      expect(find.text('Gotowe').hitTestable(), findsOneWidget);
      expect(find.text('Później').hitTestable(), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(buttons.first), before);
      await tester.tap(find.text('Gotowe'));
      await tester.tap(find.text('Później'));
      expect(primaryCalls, 1);
      expect(secondaryCalls, 1);
    });

    testWidgets('long changelog uses one scroll view at $size / $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          WhatsNewDialog(
            version: '1.3.1',
            changes: List.generate(50, (i) => 'Zmiana $i: opis aktualizacji'),
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final button = find.byType(AppButton);
      expect(button.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(size.height - 24),
      );
      final before = tester.getRect(button);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button), before);
    });
  }
}
