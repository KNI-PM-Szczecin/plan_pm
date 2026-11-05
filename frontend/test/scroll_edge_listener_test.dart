// ScrollEdgeListener: każda zakładka zgłasza własny stan „treść pod paskiem",
// także bez ruchu palcem, gdy lista powstaje już przewinięta (powrót do
// zakładki, PageStorage). Wcześniej pasek słuchał wszystkich zakładek naraz
// i po zmianie zakładki zerował stan — tytuł „Nowości" lądował na zdjęciu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';

Widget _list({ScrollController? controller}) => ListView(
  controller: controller,
  children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i'))],
);

void main() {
  testWidgets('zgłasza tylko przewinięcie własnej zakładki', (tester) async {
    final reported = <int, bool>{};
    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          children: [
            for (var page = 0; page < 2; page++)
              ScrollEdgeListener(
                onChanged: (v) => reported[page] = v,
                child: _list(),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(reported[0], isFalse);
    expect(reported[1], isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(reported[0], isTrue);
    expect(reported[1], isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(reported[0], isFalse);
  });

  testWidgets('lista zbudowana już przewinięta zgłasza stan od razu', (
    tester,
  ) async {
    bool? reported;
    final controller = ScrollController(initialScrollOffset: 200);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollEdgeListener(
          onChanged: (v) => reported = v,
          child: _list(controller: controller),
        ),
      ),
    );
    await tester.pump();
    expect(reported, isTrue);
  });

  testWidgets('ignoruje zagnieżdżone i poziome listy', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollEdgeListener(
          onChanged: (v) => reported = v,
          child: ListView(
            children: [
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 20; i++)
                      SizedBox(width: 100, child: Text('h$i')),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView(
                  children: [
                    for (var i = 0; i < 20; i++)
                      SizedBox(height: 60, child: Text('n$i')),
                  ],
                ),
              ),
              for (var i = 0; i < 20; i++) SizedBox(height: 60, child: Text('$i')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(reported, isFalse);

    await tester.drag(find.text('h0'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(reported, isFalse);

    await tester.drag(find.text('n0'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(reported, isFalse);
  });
}
