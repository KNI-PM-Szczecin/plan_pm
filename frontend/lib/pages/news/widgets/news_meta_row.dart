// Wiersz metadanych wiadomości: typ • liczba dni temu.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
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
      children: [
        Text(
          messageType.toUpperCase(),
          style: TextStyle(
            color: AppColor.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          l10n.daysAgo(DateTime.now().difference(timestamp).inDays),
          style: TextStyle(color: AppColor.onSurfaceVariant),
        ),
      ],
    );
  }
}
