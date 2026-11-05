// Szkielet listy zajęć na czas pierwszego odczytu z bazy (zimny start, zmiana
// roli lub grup): prawdziwe karty [Lecture] z atrapą danych pod Skeletonizerem
// — te same wysokości i odstępy co docelowa lista, więc treść nie „skacze",
// gdy dane przyjdą. Tekst zamienia się w kości, gradient karty zostaje — tak
// samo wygląda odświeżanie listy (shimmer na istniejących kartach).
//
// W zwykłym starcie szkielet nie ma kiedy mignąć: `app_initialization.dart`
// rozgrzewa `DatabaseService.lastLectures`, które listy podają jako
// `initialData`.
import 'package:flutter/material.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Efekt wspólny dla szkieletów i odświeżania list na stronie głównej.
const PaintingEffect lectureSkeletonEffect = ShimmerEffect(
  baseColor: Color(0x4FFFFFFF),
);

/// [count] kart z atrapą zajęć, bez własnych odstępów (jak prawdziwe karty).
List<Widget> placeholderLectures(int count) => [
  for (var i = 0; i < count; i++)
    Lecture(
      idx: i,
      name: i.isEven ? 'Podstawy programowania' : 'Matematyka stosowana',
      timeFrom: '08:00',
      timeTo: '09:30',
      location: 'Sala 101',
      group: '',
      duration: '90',
    ),
];

class LectureListSkeleton extends StatelessWidget {
  const LectureListSkeleton({super.key, this.count = 2, this.header});

  final int count;

  /// Wiersz nad kartami (data na stronie głównej, licznik w planie) —
  /// renderowany jako kość w tym samym miejscu co prawdziwy nagłówek.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: lectureSkeletonEffect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          ?header,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: placeholderLectures(count),
          ),
        ],
      ),
    );
  }
}
