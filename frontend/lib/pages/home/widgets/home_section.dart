// Sekcja strony głównej: nagłówek sekcji (jak w [AppSection] — wersaliki na
// iOS, zdanie w akcencie na Androidzie) nad dowolną treścią.
// Używany w [HomePage] (sekcja newsów) i [TodayLectures] (sekcja zajęć) —
// zmienia się tylko nagłówek, karty zajęć pod nim zostają bez zmian.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/widgets/app_section.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({super.key, required this.title, this.child});

  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AppSection(header: title, child: child ?? const SizedBox.shrink());
  }
}
