// Boczny panel nawigacyjny aplikacji (makieta 4a/4c): płaska powierzchnia
// bez cienia, ikona i nazwa aplikacji, skróty do PE, legitymacji i wirtualnej
// uczelni oraz na dole opinia, „Co nowego" i ustawienia.
//
// Skróty do stron uczelni mają strzałkę ↗ — otwierają przeglądarkę od razu;
// wiersze z chevronem otwierają ekran w aplikacji.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_icon_tile.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.onPeTap,
    required this.onStudentIdTap,
    required this.onVirtualUniversityTap,
    required this.onFeedbackTap,
    required this.onSettingsTap,
    required this.onWhatsNewTap,
  });

  final VoidCallback onPeTap;
  final VoidCallback onStudentIdTap;
  final VoidCallback onVirtualUniversityTap;
  final VoidCallback onFeedbackTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onWhatsNewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const indent = AppGroupedSection.iconRowDividerIndent;

    AppListRow row(
      IconData icon,
      Color color,
      String label,
      VoidCallback onTap, {
      bool external = false,
    }) => AppListRow(
      leading: AppIconBadge(icon: icon, color: color),
      title: label,
      accessory: external
          ? AppListRowAccessory.external
          : AppListRowAccessory.chevron,
      onTap: onTap,
    );

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.84,
      decoration: BoxDecoration(
        color: AppColor.groupedBackground,
        border: Border(right: BorderSide(color: AppColor.separator)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Row(
                  spacing: 14,
                  children: [
                    const AppIconTile(size: 48),
                    Text(
                      'Plan PM',
                      style: AppTextStyle.title2Emphasized.copyWith(
                        color: AppColor.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppGroupedSection(
                        dividerIndent: indent,
                        children: [
                          row(
                            LucideIcons.activity,
                            AppColor.systemRed,
                            l10n.pePageTitle,
                            onPeTap,
                            external: true,
                          ),
                          row(
                            LucideIcons.creditCard,
                            AppColor.systemGreen,
                            l10n.studentIdPageTitle,
                            onStudentIdTap,
                            external: true,
                          ),
                          row(
                            LucideIcons.landmark,
                            AppColor.systemBlue,
                            l10n.virtualUniversityPageTitle,
                            onVirtualUniversityTap,
                            external: true,
                          ),
                        ],
                      ),
                      AppGroupedSection(
                        dividerIndent: indent,
                        children: [
                          row(
                            LucideIcons.messageSquare,
                            AppColor.systemGreen,
                            l10n.sendFeedbackButton,
                            onFeedbackTap,
                            external: true,
                          ),
                          row(
                            LucideIcons.sparkles,
                            AppColor.systemPurple,
                            l10n.whatsNewTitle,
                            onWhatsNewTap,
                          ),
                          row(
                            LucideIcons.settings,
                            AppColor.systemGray,
                            l10n.pageTitleSettings,
                            onSettingsTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
