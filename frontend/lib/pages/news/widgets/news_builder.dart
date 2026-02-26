import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/widgets/generic_loading.dart';
import 'package:plan_pm/global/widgets/generic_no_resource.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/home/widgets/news_card.dart';
import 'package:plan_pm/service/database_service.dart';

class NewsBuilder extends StatelessWidget {
  const NewsBuilder({super.key, this.limit = 9999});

  final int? limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final databaseService = DatabaseService.instance;
    return FutureBuilder<List<NewsModel>>(
      future: databaseService.fetchNews(limit: limit!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return GenericNoResource(
            label: l10n.unexpectedError,
            icon: LucideIcons.bug,
            description: snapshot.error.toString(),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return GenericLoading(label: "Ładowanie aktualności");
        }
        if (snapshot.data != null && snapshot.data!.isEmpty) {
          return GenericNoResource(
            label: "Brak aktualności",
            icon: LucideIcons.calendarX,
            description:
                "Brak nowych wiadomości. Sprawdź później, aby zobaczyć aktualizacje.",
          );
        }
        final List<NewsModel> data = snapshot.data!;
        return Column(
          children: data
              .map(
                (news) => NewsCard(
                  title: news.title,
                  messageType: news.messageType,
                  description: news.content,
                  timestamp: news.createdAt,
                  imageUrl: news.imageUrl,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
