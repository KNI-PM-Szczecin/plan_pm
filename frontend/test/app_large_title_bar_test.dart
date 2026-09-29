// AppLargeTitleBar: przy zmianie zakładki stary i nowy tytuł stoją przy lewej
// krawędzi przez całe przejście — wcześniej były centrowane względem siebie
// i krótszy tytuł „skakał" w lewo na końcu animacji (Zajęcia → Nowości).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';

Widget _bar(String title) => MaterialApp(
  home: Scaffold(
    appBar: AppLargeTitleBar(title: title, leading: const SizedBox()),
  ),
);

void main() {
  testWidgets('tytuł nie przesuwa się w poziomie przy zmianie zakładki', (
    tester,
  ) async {
    await tester.pumpWidget(_bar('Zajęcia'));
    final left = tester.getTopLeft(find.text('Zajęcia')).dx;

    await tester.pumpWidget(_bar('Nowości — dłuższy tytuł'));
    await tester.pump(const Duration(milliseconds: 90)); // połowa przejścia

    expect(tester.getTopLeft(find.text('Zajęcia')).dx, left);
    expect(tester.getTopLeft(find.text('Nowości — dłuższy tytuł')).dx, left);

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Nowości — dłuższy tytuł')).dx, left);
  });
}
