// Pełny widok pojedynczej wiadomości: okładka jako hero na pełną szerokość
// od samej góry ekranu (pod paskiem statusu), kategoria i data nad tytułem,
// treść HTML bezpośrednio na tle. Makieta 6a kładła zaokrągloną okładkę pod
// paskiem „Szczegóły" — dwa nagłówki jeden nad drugim spychały tytuł poniżej
// połowy ekranu (decyzja z 07.11.2026). Bez zdjęcia zostaje zwykły pasek.
//
// Pasek nad hero jest przezroczysty i bez tytułu; tło i tytuł dostaje, gdy
// okładka wjedzie pod niego ([CustomAppBar.scrollEdgeOffset]). Na iOS
// okładka rozciąga się przy przeciągnięciu w dół (SliverAppBar.stretch).
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/external_links.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/news/widgets/news_cover_image.dart';
import 'package:plan_pm/pages/news/widgets/news_html_style.dart';
import 'package:plan_pm/pages/news/widgets/news_meta_row.dart';

class FullNewsPage extends StatelessWidget {
  const FullNewsPage({
    super.key,
    required this.title,
    required this.messageType,
    required this.description,
    required this.timestamp,
    this.imageUrl,
  });

  final String title;
  final String messageType;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  /// Wysokość okładki licząc od górnej krawędzi ekranu (z paskiem statusu).
  static const double heroHeight = 300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasHero = imageUrl != null;
    // Tu (nad Scaffoldem) padding.top to sam pasek statusu.
    final statusBar = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColor.background,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: l10n.details,
        scrollEdgeOffset: hasHero
            ? heroHeight - statusBar - CustomAppBar.height
            : 0,
      ),
      body: Builder(
        builder: (context) {
          // Pod Scaffoldem padding.top zawiera już wysokość paska.
          final padding = MediaQuery.paddingOf(context);
          return CustomScrollView(
            slivers: [
              if (hasHero)
                SliverAppBar(
                  primary: false,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                  expandedHeight: heroHeight,
                  stretch: true,
                  forceMaterialTransparency: true,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: NewsCoverImage(
                      imageUrl: imageUrl!,
                      aspectRatio: null,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  hasHero ? 16 : padding.top + 8,
                  16,
                  padding.bottom + 48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 6,
                          children: [
                            NewsMetaRow(
                              messageType: messageType,
                              timestamp: timestamp,
                            ),
                            Text(
                              title,
                              style: AppTextStyle.title2Emphasized.copyWith(
                                color: AppColor.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Html(
                        data: description,
                        style: newsHtmlStyle(),
                        // Linki w treści wyglądają jak linki (akcent), więc
                        // muszą się otwierać — bez tego tap nic nie robił.
                        onLinkTap: (url, _, _) {
                          if (url != null) {
                            openExternalLinkOrNotify(context, url);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
