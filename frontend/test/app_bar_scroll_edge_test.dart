// CustomAppBar: tło (blur/fill) pojawia się dopiero, gdy treść wjedzie pod pasek.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_grouped_page.dart';

/// Docelowa wartość animacji tła paska: 0 = przezroczysty, 1 = blur/tło.
double? _barTarget(WidgetTester tester) => tester
    .widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byType(CustomAppBar),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    )
    .tween
    .end;

void main() {
  testWidgets(
    'pasek jest przezroczysty na górze i dostaje tło po przewinięciu',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppGroupedPage(
            title: 'Test',
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('$i')),
            ],
          ),
        ),
      );
      expect(_barTarget(tester), 0);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(_barTarget(tester), 1);
      // Tło musi mieć wysokość paska — flexibleSpace ma luźne ograniczenia i
      // bez rozciągnięcia tło zwijało się do 0 px (niewidoczne na urządzeniu).
      final barHeight = tester.getSize(find.byType(CustomAppBar)).height;
      final background = find.descendant(
        of: find.byType(CustomAppBar),
        matching: find.byType(TweenAnimationBuilder<double>),
      );
      expect(tester.getSize(background).height, barHeight);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();
      expect(_barTarget(tester), 0);
    },
  );

  testWidgets(
    'z hero pasek dostaje tło i tytuł dopiero za progiem scrollEdgeOffset',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const CustomAppBar(title: 'Szczegóły', scrollEdgeOffset: 200),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 60, child: Text('$i')),
                ],
              ),
            ),
          ),
        ),
      );
      double titleOpacity() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(CustomAppBar),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;

      // Na górze: przezroczysty i bez tytułu (tytuł leżałby na zdjęciu).
      expect(_barTarget(tester), 0);
      expect(titleOpacity(), 0);

      // Przewinięcie krótsze niż próg — hero wciąż pod paskiem, nic się nie dzieje.
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(_barTarget(tester), 0);
      expect(titleOpacity(), 0);

      // Za progiem treść wjeżdża pod pasek: tło i tytuł.
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_barTarget(tester), 1);
      expect(titleOpacity(), 1);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(_barTarget(tester), 0);
      expect(titleOpacity(), 0);
    },
  );
}
