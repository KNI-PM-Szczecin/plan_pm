// Wiersz etykieta + wartość używany w kartach informacyjnych ([StudentInfo], [LecturerInfo]).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class InfoText extends StatelessWidget {
  const InfoText({super.key, required this.title, required this.content});

  final String title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: AppTextSize.subhead, color: AppColor.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              content ?? l10n.dataNaN,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: AppTextSize.subhead,
                color: AppColor.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
