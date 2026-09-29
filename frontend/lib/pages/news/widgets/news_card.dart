// Karta wiadomości na liście (Strona główna, Nowości — makiety 3a/8a):
// okładka, kategoria i data, tytuł, dwie linie zajawki i „Czytaj dalej".
// Po tapnięciu otwiera [FullNewsPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
import 'package:plan_pm/pages/news/full_news_page.dart';
import 'package:plan_pm/pages/news/widgets/news_cover_image.dart';
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
  });

  final String title;
  final String messageType;

  /// Treść w HTML — w karcie pokazujemy z niej tylko początek zwykłym tekstem.
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  static const double radius = 22;

  /// Zajawka bez znaczników HTML i encji — [Text] z maxLines ucina ją ładnie
  /// na końcu drugiej linii zamiast w połowie tagu.
  static String _plainText(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>|</h\d>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPressable(
      color: AppColor.groupedSurface,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
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
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null) NewsCoverImage(imageUrl: imageUrl!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  NewsMetaRow(messageType: messageType, timestamp: timestamp),
                  Text(
                    title,
                    style: AppTextStyle.headline.copyWith(
                      color: AppColor.onSurface,
                    ),
                  ),
                  Text(
                    _plainText(description),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subheadline.copyWith(
                      color: AppColor.labelSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      spacing: 4,
                      children: [
                        Text(
                          l10n.readMore,
                          style: AppTextStyle.subheadline.copyWith(
                            color: AppColor.primary,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppColor.primary,
                        ),
                      ],
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
