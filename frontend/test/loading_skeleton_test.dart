// Szkielety zimnego startu (LectureListSkeleton, NewsCard.placeholder): mają
// się zbudować na szerokości telefonu bez overflow i zamienić tekst w kości,
// a atrapa newsa nie może być klikalna.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture_skeleton.dart';
import 'package:plan_pm/pages/news/widgets/news_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('pl'),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  // Globalne notifiery, które czytają karta Lecture i AppColor.
  setUpAll(() {
    accentColorNotifier = AccentColorNotifier();
    eventColorStyleNotifier = EventColorStyleNotifier();
  });

  testWidgets('szkielet zajęć: nagłówek i N kart pod Skeletonizerem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const LectureListSkeleton(count: 3, header: Text('Piątek'))),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Lecture), findsNWidgets(3));
    expect(find.text('Piątek'), findsOneWidget);
  });

  testWidgets('atrapa newsa buduje się bez overflow i nie jest klikalna', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const Skeletonizer(child: NewsCard.placeholder())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<AppPressable>(find.byType(AppPressable)).onTap,
      isNull,
    );
    // Okładka-kość o proporcji prawdziwej okładki.
    expect(find.byType(AspectRatio), findsOneWidget);
  });
}
