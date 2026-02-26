import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/news/full_news_page.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppColor.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.outline, width: 1),
      ),
      elevation: 1,
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
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                imageBuilder: (context, imageProvider) => Ink.image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                ),
                placeholder: (context, url) =>
                    Skeleton.leaf(child: SizedBox(height: 150)),
                // Container(),
                errorWidget: (context, url, error) =>
                    const Icon(LucideIcons.eggFried),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 5,
                    children: [
                      Text(
                        messageType,
                        style: TextStyle(color: AppColor.onSurfaceVariant),
                      ),
                      Text(
                        "•",
                        style: TextStyle(color: AppColor.onSurfaceVariant),
                      ),
                      Text(
                        l10n.daysAgo(
                          DateTime.now().difference(timestamp).inDays,
                        ),
                        style: TextStyle(color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColor.onSurface,
                    ),
                  ),
                  Html(
                    data: "${description.substring(0, 45)}...",
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize.medium,
                        color: AppColor.onSurfaceVariant,
                      ),
                      "a": Style(
                        color: Colors.blue,
                        textDecoration: TextDecoration.underline,
                      ),
                      "h1": Style(
                        fontSize: FontSize.xxLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    },
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
