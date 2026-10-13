// Pobiera wiadomości z bazy i buduje listę [NewsCard] — obsługuje stany ładowania, błędu i braku danych
// ([AppStateCard]).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/widgets/app_state_card.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/news/widgets/news_card.dart';
import 'package:plan_pm/service/database_service.dart';

class NewsBuilder extends StatefulWidget {
  const NewsBuilder({super.key, this.limit = 9999});

  final int? limit;

  @override
  State<NewsBuilder> createState() => _NewsBuilderState();
}

class _NewsBuilderState extends State<NewsBuilder> {
  late Future<List<NewsModel>> _future;
  List<NewsModel>? _cached;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.fetchNews(limit: widget.limit!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<NewsModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) _cached = snapshot.data;

        if (snapshot.hasError && _cached == null) {
          return AppStateCard(
            icon: LucideIcons.bug,
            title: l10n.unexpectedError,
            message: snapshot.error.toString(),
          );
        }
        if (snapshot.connectionState != ConnectionState.done && _cached == null) {
          return AppStateCard.loading(title: l10n.newsLoading);
        }

        final data = snapshot.data ?? _cached ?? [];
        if (data.isEmpty) {
          return AppStateCard(
            icon: LucideIcons.newspaper,
            title: l10n.noNews,
            message: l10n.newsNoDataDescription,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
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
