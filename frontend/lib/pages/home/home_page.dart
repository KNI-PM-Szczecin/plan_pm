// Strona główna aplikacji — wyświetla najnowszy news i nadchodzące zajęcia.
// Obsługuje pull-to-refresh: odświeża cache (zajęcia + newsy) i sygnalizuje
// [TodayLectures] przez [_refreshNotifier] aby przebudował swój Future.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/home/widgets/home_section.dart';
import 'package:plan_pm/pages/home/widgets/today_lectures.dart';
import 'package:plan_pm/pages/news/widgets/news_builder.dart';
import 'package:plan_pm/service/cache_service.dart';

import 'package:plan_pm/global/utils/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.d("Refreshing home page elements...");
        final CacheService cacheService = CacheService();
        await cacheService.syncLectures();
        await cacheService.syncNews();

        // Notify TodayLectures to reset its Future and recalculate time to 'now'
        _refreshNotifier.value++;
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom:
              kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              HomeSection(
                title: l10n.newsSectionLabel,
                child: NewsBuilder(
                  limit: 1,
                  descriptionColor: AppColor.onSurfaceVariant,
                ),
              ),
              TodayLectures(refreshNotifier: _refreshNotifier),
            ],
          ),
        ),
      ),
    );
  }
}
