// Stopka pod planem — krótkie zastrzeżenie z linkiem do oficjalnego planu
// uczelni (wymóg uczelni, 10.2026).
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const String kOfficialScheduleUrl = 'https://plany.am.szczecin.pl';

Future<void> openOfficialSchedule(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final opened = await launchUrl(
    Uri.parse(kOfficialScheduleUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!opened) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
  }
}

class OfficialScheduleNote extends StatelessWidget {
  const OfficialScheduleNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTextStyle.footnote.copyWith(
      color: AppColor.labelSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppPressable(
        onTap: () => openOfficialSchedule(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Text.rich(
          TextSpan(
            text: '${l10n.noticeFooter} ',
            children: [
              TextSpan(
                text: '↗',
                style: style.copyWith(color: AppColor.primary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
