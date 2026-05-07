// Pełny widok pojedynczej wiadomości — okładka (300px), nagłówek metadanych i treść HTML.
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: CustomAppBar(title: l10n.details),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Card(
              color: AppColor.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColor.outline, width: 1),
              ),
              elevation: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    NewsCoverImage(imageUrl: imageUrl!, height: 300),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NewsMetaRow(
                          messageType: messageType,
                          timestamp: timestamp,
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColor.onSurface,
                          ),
                        ),
                        Html(data: description, style: newsHtmlStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
