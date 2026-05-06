// Strona wiadomości — przewijalna lista kart budowanych przez [NewsBuilder].
import 'package:flutter/material.dart';
import 'package:plan_pm/pages/news/widgets/news_builder.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [NewsBuilder()]),
      ),
    );
  }
}
