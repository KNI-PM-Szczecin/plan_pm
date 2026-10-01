// Pełny widok pojedynczej wiadomości (makieta 6a): artykuł bez karty —
// okładka na pełną szerokość z zaokrągleniem, kategoria i data nad tytułem,
// treść HTML bezpośrednio na tle.
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/news/widgets/news_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: l10n.details),
      body: Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              padding.top + 8,
              16,
              padding.bottom + 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                if (imageUrl != null)
                  NewsCoverImage(
                    imageUrl: imageUrl!,
                    aspectRatio: 1.25,
                    borderRadius: BorderRadius.circular(NewsCard.radius),
                  ),
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
                Html(data: description, style: newsHtmlStyle()),
              ],
            ),
          );
        },
      ),
    );
  }
}
