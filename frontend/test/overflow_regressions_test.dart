// Regresje overflow z audytu przed powrotem do sklepów: menu boczne w
// poziomie i przy dużej czcionce, wiersz etykieta/wartość przy dużej
// czcionce z długą etykietą, wybór wykładowcy w poziomie z klawiaturą.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/sidebar.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';

Widget _app(Widget home, {double textScale = 1, EdgeInsets viewInsets = EdgeInsets.zero}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('uk'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: viewInsets,
        ),
        child: child!,
      ),
      home: home,
    );

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Sidebar _sidebar() => Sidebar(
  onPeTap: () {},
  onStudentIdTap: () {},
  onVirtualUniversityTap: () {},
  onFeedbackTap: () {},
  onSettingsTap: () {},
  onWhatsNewTap: () {},
);

void main() {
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
  });

  testWidgets('menu boczne: poziom 844×390 bez overflow, dół osiągalny', (
    tester,
  ) async {
    _size(tester, const Size(844, 390));
    await tester.pumpWidget(_app(Scaffold(body: _sidebar())));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu boczne: 375×667 przy skali tekstu 1.5 bez overflow', (
    tester,
  ) async {
    _size(tester, const Size(375, 667));
    await tester.pumpWidget(_app(Scaffold(body: _sidebar()), textScale: 1.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wiersz etykieta/wartość: długa etykieta przy skali 2.0', (
    tester,
  ) async {
    _size(tester, const Size(375, 667));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AppGroupedSection(
            children: const [
              AppListRow(
                title: 'Лабораторні роботи з програмування',
                value: 'Група L01 та ще довше значення',
              ),
            ],
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wiersz etykieta/wartość: wartość dosunięta do prawej krawędzi', (
    tester,
  ) async {
    _size(tester, const Size(375, 667));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AppGroupedSection(
            children: const [
              AppListRow(title: 'Kierunek', value: 'Informatyka'),
              AppListRow(title: 'Rok', value: '2'),
            ],
          ),
        ),
      ),
    );
    // Sekcja zajmuje całą szerokość, wiersz ma 16 pt paddingu — prawa
    // krawędź wartości to 375 − 16 (regresja: Flexible+Expanded w jednym Row
    // zostawiało wartość w połowie wiersza).
    for (final value in ['Informatyka', '2']) {
      expect(tester.getTopRight(find.text(value)).dx, 375 - 16);
    }
  });

  testWidgets('wybór wykładowcy: poziom z klawiaturą bez overflow', (
    tester,
  ) async {
    _size(tester, const Size(844, 390));
    await tester.pumpWidget(
      _app(
        LecturerSelectionPage(
          lecturers: [
            for (var i = 0; i < 20; i++)
              LecturerItem(id: '$i', name: 'Wykładowca $i', title: 'dr'),
          ],
          onContinue: (_) async {},
        ),
        viewInsets: const EdgeInsets.only(bottom: 160),
      ),
    );
    expect(tester.takeException(), isNull);
    // Lista jest pod nagłówkiem i wyszukiwarką — po przewinięciu widać kafelki.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Wykładowca 0'), findsOneWidget);
  });
}
