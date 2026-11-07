import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/welcome/notice_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('acknowledging saves the flag and replaces itself with next', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const NoticePage(next: Scaffold(body: Text('next')))),
    );

    expect(find.text('Od studentów dla studentów'), findsOneWidget);
    expect(find.textContaining('plany.am.szczecin.pl'), findsOneWidget);

    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();

    expect(find.text('next'), findsOneWidget);
    expect(find.byType(NoticePage), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kNoticeAcknowledgedKey), isTrue);
  });

  testWidgets('read-only mode just closes and does not touch the flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticePage()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kNoticeAcknowledgedKey), isNull);
  });
}
