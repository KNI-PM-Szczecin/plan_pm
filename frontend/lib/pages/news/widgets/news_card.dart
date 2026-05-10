// Karta wiadomości na liście — okładka, typ, tytuł i skrócony opis z linkiem "czytaj więcej".
// Po tapnięciu otwiera [FullNewsPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/pages/news/full_news_page.dart';
import 'package:plan_pm/pages/news/widgets/news_cover_image.dart';
import 'package:plan_pm/pages/news/widgets/news_html_style.dart';
import 'package:plan_pm/pages/news/widgets/news_meta_row.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.title,
    required this.messageType,
    required this.description,
    required this.timestamp,
    this.imageUrl,
    this.descriptionColor,
  });

  final String title;
  final String messageType;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;
  final Color? descriptionColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppColor.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColor.outline.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullNewsPage(
                title: title,
                messageType: messageType,
                description: description,
                timestamp: timestamp,
                imageUrl: imageUrl,
              ),
            ),
          );
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) NewsCoverImage(imageUrl: imageUrl!),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NewsMetaRow(messageType: messageType, timestamp: timestamp),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColor.onSurface,
                    ),
                  ),
                  Html(
                    data: description.length > 45
                        ? "${description.substring(0, 45)}..."
                        : description,
                    style: {
                      ...newsHtmlStyle,
                      "body": (newsHtmlStyle["body"] ?? Style()).copyWith(
                        color: descriptionColor ?? AppColor.onSurfaceVariant,
                      ),
                      "p": (newsHtmlStyle["p"] ?? Style()).copyWith(
                        color: descriptionColor ?? AppColor.onSurfaceVariant,
                      ),
                    },
                  ),
                  Text(
                    l10n.readMore,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
