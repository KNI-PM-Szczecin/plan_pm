// Ekran zgody RODO — pokazywany przy wyborze wykładowcy (gdy kDebugGdpr = true).
// Żeby przejść dalej, użytkownik musi zaakceptować; przyciskiem wstecz może anulować.
// Nie zapisuje stanu zgody — każde wejście wymaga ponownej akceptacji.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_bottom_actions.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_hero_icon.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_screen_header.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GdprConsentPage extends StatelessWidget {
  const GdprConsentPage({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (l10n.gdprCard1Title, l10n.gdprCard1Body, AppColor.systemBlue),
      (l10n.gdprCard2Title, l10n.gdprCard2Body, AppColor.systemIndigo),
      (l10n.gdprCard3Title, l10n.gdprCard3Body, AppColor.systemGreen),
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                spacing: 24,
                children: [
                  AppScreenHeader(
                    leading: AppHeroIcon(
                      icon: LucideIcons.shieldCheck,
                      color: AppColor.systemBlue,
                    ),
                    leadingSpacing: 20,
                    title: l10n.gdprTitle,
                  ),
                  AppGroupedSection(
                    children: [
                      for (final (i, (title, body, color)) in steps.indexed)
                        AppListRow(
                          alignTop: true,
                          emphasized: true,
                          leading: AppIconBadge(
                            label: '${i + 1}',
                            color: color,
                          ),
                          title: title,
                          subtitle: body,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppBottomActions(
            primary: AppButton(
              label: l10n.gdprAccept,
              onPressed: () {
                Navigator.of(context).pop();
                onAccepted();
              },
            ),
            note: l10n.gdprRevoke,
          ),
        ],
      ),
    );
  }
}
