// Szkielet ekranu z sekcjami (Ustawienia, Wygląd, Język, O aplikacji):
// tło grupowane, [CustomAppBar] z tytułem i przewijana kolumna sekcji
// co [AppSection.spacing]. Treść wjeżdża pod pasek (scroll edge w CustomAppBar).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_section.dart';

class AppGroupedPage extends StatelessWidget {
  const AppGroupedPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;

  /// Zwykle [AppSection]y; odstępy między nimi dokłada strona.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: title,
        backgroundColor: AppColor.groupedBackground,
      ),
      body: Builder(
        // Builder, bo dopiero pod Scaffoldem MediaQuery zawiera wysokość paska.
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              padding.top + 16,
              16,
              padding.bottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSection.spacing,
              children: children,
            ),
          );
        },
      ),
    );
  }
}
