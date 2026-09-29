// Sekcja z wybranymi grupami studenta — kody grup w jednej karcie.
// Akcja "Zmień grupy" otwiera [GroupSelectionPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GroupInfo extends StatelessWidget {
  const GroupInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pokazujemy sam kod grupy (bez puli i rocznika) — pełny kod siedzi w prefs.
    final codes = (Student.selectedGroups ?? [])
        .expand((group) => group.split(","))
        .map(
          (g) => g.split("/")[0].trim().replaceAll("(", "").replaceAll(")", ""),
        )
        .where((code) => code.isNotEmpty)
        .toList();

    return AppSection(
      header: l10n.selectedGroupsHeader,
      actionLabel: l10n.changeGroupsButton,
      onAction: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupSelectionPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: AppColor.groupedSurface,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(AppGroupedSection.radius),
          ),
        ),
        child: codes.isEmpty
            ? Text(
                l10n.noDataAvailable,
                style: AppTextStyle.body.copyWith(
                  color: AppColor.labelSecondary,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in codes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColor.fillTertiary,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        code,
                        style: AppTextStyle.subheadlineEmphasized.copyWith(
                          color: AppColor.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
