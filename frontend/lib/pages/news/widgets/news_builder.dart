// Pobiera wiadomości z bazy i buduje listę [NewsCard] — obsługuje stany
// błędu i braku danych ([AppStateCard]) oraz ładowania (szkielet kart).
//
// Dane trzyma w stanie: [refreshNotifier] (pull-to-refresh na stronie
// głównej) odczytuje bazę ponownie, ale stara lista zostaje na ekranie, aż
// przyjdzie nowa — bez klatki szkieletu i skoku treści. Pierwszą klatkę
// zasila ostatni odczyt z bazy (`DatabaseService.lastNews`, rozgrzany przy
// starcie); szkielet widać tylko na zimny start.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/widgets/app_state_card.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lectures/widgets/lecture_skeleton.dart';
import 'package:plan_pm/pages/news/widgets/news_card.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsBuilder extends StatefulWidget {
  const NewsBuilder({
    super.key,
    this.limit = DatabaseService.newsLimitAll,
    this.refreshNotifier,
  });

  final int limit;
  final ValueNotifier<int>? refreshNotifier;

  @override
  State<NewsBuilder> createState() => _NewsBuilderState();
}

class _NewsBuilderState extends State<NewsBuilder> {
  late Future<List<NewsModel>> _future;
  List<NewsModel>? _cached;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_refresh);
    _fetch();
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(_fetch);

  void _fetch() {
    _cached ??= DatabaseService.instance.lastNews(widget.limit);
    _future = DatabaseService.instance.fetchNews(limit: widget.limit);
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
        if (snapshot.connectionState != ConnectionState.done &&
            _cached == null) {
          return Skeletonizer(
            effect: lectureSkeletonEffect,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (var i = 0; i < min(widget.limit, 3); i++)
                  const NewsCard.placeholder(),
              ],
            ),
          );
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
