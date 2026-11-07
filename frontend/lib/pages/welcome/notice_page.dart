// Informacja „od studentów dla studentów" — wymóg uczelni przy warunkowej
// zgodzie na udostępnienie aplikacji (10.2026): logo KNI, nieoficjalny
// charakter aplikacji i pierwszeństwo planu na stronie uczelni.
// Pokazywana raz: w onboardingu i jednorazowo dotychczasowym użytkownikom
// (patrz [app_initialization.dart]). Z „O aplikacji" otwiera się do wglądu.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_bottom_actions.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_screen_header.dart';
import 'package:plan_pm/global/widgets/official_schedule_note.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kNoticeAcknowledgedKey = 'unofficial_notice_acknowledged';

class NoticePage extends StatelessWidget {
  /// [next] == null → tryb do wglądu: „Rozumiem" tylko zamyka ekran.
  const NoticePage({super.key, this.next});

  /// Ekran, który zastępuje ten po potwierdzeniu.
  final Widget? next;

  Future<void> _acknowledge(BuildContext context) async {
    final next = this.next;
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNoticeAcknowledgedKey, true);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (
        LucideIcons.users,
        AppColor.systemBlue,
        l10n.noticeAuthorsTitle,
        l10n.noticeAuthorsBody,
      ),
      (
        LucideIcons.info,
        AppColor.systemOrange,
        l10n.noticeSupplementaryTitle,
        l10n.noticeSupplementaryBody,
      ),
      (
        LucideIcons.landmark,
        AppColor.systemGreen,
        l10n.noticeOfficialTitle,
        l10n.noticeOfficialBody,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColor.groupedBackground,
      // Dotychczasowy użytkownik dostaje ekran jako korzeń — nie ma dokąd wrócić.
      appBar: CustomAppBar(
        backgroundColor: AppColor.groupedBackground,
        leading: Navigator.of(context).canPop()
            ? null
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                spacing: 24,
                children: [
                  AppScreenHeader(
                    leading: ClipOval(
                      child: Image.asset(
                        'assets/kni_logo.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    leadingSpacing: 20,
                    title: l10n.noticeTitle,
                    subtitle: l10n.noticeSubtitle,
                  ),
                  AppGroupedSection(
                    children: [
                      for (final (icon, color, title, body) in rows)
                        AppListRow(
                          alignTop: true,
                          emphasized: true,
                          leading: AppIconBadge(icon: icon, color: color),
                          title: title,
                          subtitle: body,
                        ),
                    ],
                  ),
                  AppGroupedSection(
                    children: [
                      AppListRow(
                        leading: AppIconBadge(
                          icon: LucideIcons.calendarDays,
                          color: AppColor.systemIndigo,
                        ),
                        title: l10n.noticeOpenOfficial,
                        titleColor: AppColor.primary,
                        accessory: AppListRowAccessory.external,
                        onTap: () => openOfficialSchedule(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppBottomActions(
            primary: AppButton(
              label: l10n.noticeAccept,
              onPressed: () => _acknowledge(context),
            ),
          ),
        ],
      ),
    );
  }
}
