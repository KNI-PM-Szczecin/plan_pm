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
import 'package:plan_pm/pages/news/utils/html_preview.dart';
import 'package:plan_pm/pages/news/widgets/news_cover_image.dart';
import 'package:plan_pm/pages/news/widgets/news_meta_row.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.title,
    required this.messageType,
    required this.description,
    required this.timestamp,
    this.imageUrl,
  }) : _placeholder = false;

  /// Atrapa do szkieletu ([NewsBuilder] pod Skeletonizerem): ta sama karta
  /// z wymyśloną treścią i pustą okładką o proporcji prawdziwej — wysokość
  /// jak u docelowej karty, więc lista nie skacze po załadowaniu.
  const NewsCard.placeholder({super.key})
    : title = 'Zmiany w planie zajęć od nowego semestru',
      messageType = 'Ogłoszenie',
      description =
          'Od poniedziałku obowiązuje zaktualizowany plan zajęć. Sprawdź '
          'godziny i sale swoich przedmiotów.',
      timestamp = null,
      imageUrl = null,
      _placeholder = true;

  /// Czy karta jest atrapą (okładka-kość, bez akcji).
  final bool _placeholder;

  final String title;
  final String messageType;

  /// Treść w HTML — w karcie pokazujemy z niej tylko początek zwykłym tekstem.
  final String description;

  /// `null` tylko w atrapie.
  final DateTime? timestamp;
  final String? imageUrl;

  static const double radius = 22;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPressable(
      color: AppColor.groupedSurface,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      onTap: _placeholder
          ? null
          : () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullNewsPage(
                    title: title,
                    messageType: messageType,
                    description: description,
                    timestamp: timestamp!,
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
            if (_placeholder)
              const Skeleton.leaf(child: AspectRatio(aspectRatio: 2.5))
            else if (imageUrl != null)
              NewsCoverImage(imageUrl: imageUrl!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  NewsMetaRow(
                    messageType: messageType,
                    timestamp: timestamp ?? DateTime.now(),
                  ),
                  Text(
                    title,
                    style: AppTextStyle.headline.copyWith(
                      color: AppColor.onSurface,
                    ),
                  ),
                  Text(
                    htmlPreviewText(description),
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
