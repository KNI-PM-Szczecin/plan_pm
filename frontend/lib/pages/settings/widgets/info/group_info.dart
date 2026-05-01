// Karta z wybranymi grupami studenta wyświetlanymi jako chipy.
// Przycisk "Zmień grupy" otwiera [GroupSelectionPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/pages/settings/widgets/controls/themed_outline_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu/menu_section.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GroupInfo extends StatelessWidget {
  const GroupInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuSection(
      title: l10n.selectedGroupsHeader,
      action: [
        ThemedOutlineButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GroupSelectionPage(),
              ),
            );
          },
          label: l10n.changeGroupsButton,
          icon: LucideIcons.edit3,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectedGroupsLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.onSurfaceVariant,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      Student.selectedGroups != null &&
                          Student.selectedGroups!.isNotEmpty
                      ? Student.selectedGroups!
                            .expand((group) => group.split(","))
                            .map(
                              (g) => Container(
                                decoration: BoxDecoration(
                                  color: AppColor.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColor.outline),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 7,
                                  ),
                                  child: Text(
                                    g
                                        .split("/")[0]
                                        .trim()
                                        .replaceAll("(", "")
                                        .replaceAll(")", ""),
                                    style: TextStyle(color: AppColor.onSurface),
                                  ),
                                ),
                              ),
                            )
                            .toList()
                      : [
                          Text(
                            l10n.noDataAvailable,
                            style: TextStyle(color: AppColor.onSurface),
                          ),
                        ],
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
