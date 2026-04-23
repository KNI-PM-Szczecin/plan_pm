// Strona wiadomości — przewijalna lista kart budowanych przez [NewsBuilder].
import 'package:flutter/material.dart';
import 'package:plan_pm/pages/news/widgets/news_builder.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [NewsBuilder()]),
      ),
    );
  }
}
