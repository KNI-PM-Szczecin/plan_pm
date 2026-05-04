// Wiersz etykieta + wartość używany w kartach informacyjnych ([StudentInfo], [LecturerInfo]).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class InfoText extends StatelessWidget {
  const InfoText({super.key, required this.title, required this.content});

  final String title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppColor.onSurfaceVariant),
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              content ?? l10n.dataNaN,
              softWrap: true,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.onSurface,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
