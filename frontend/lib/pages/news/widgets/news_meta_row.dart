// Wiersz metadanych wiadomości: kategoria (akcent, wersaliki) i „ile dni temu".
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class NewsMetaRow extends StatelessWidget {
  const NewsMetaRow({
    super.key,
    required this.messageType,
    required this.timestamp,
  });

  final String messageType;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            messageType.toUpperCase(),
            style: AppTextStyle.footnoteEmphasized.copyWith(
              color: AppColor.primary,
            ),
          ),
        ),
        Text(
          l10n.daysAgo(DateTime.now().difference(timestamp).inDays),
          style: AppTextStyle.footnote.copyWith(color: AppColor.labelSecondary),
        ),
      ],
    );
  }
}
