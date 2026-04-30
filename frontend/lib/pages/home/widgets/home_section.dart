// Sekcja strony głównej z tytułem i zawartością.
// Prosty wrapper — tytuł pogrubiony nad dowolnym widżetem dzieckiem.
// Używany w [HomePage] (sekcja newsów) i [TodayLectures] (sekcja zajęć).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({super.key, required this.title, this.child});

  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColor.onBackground,
          ),
        ),
        ?child,
      ],
    );
  }
}
