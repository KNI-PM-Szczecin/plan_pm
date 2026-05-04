// Karta z danymi akademickimi studenta — wydział, kierunek, specjalizacja, rok, tryb studiów.
// Przycisk "Edytuj" otwiera [InputPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/pages/settings/widgets/info/info_text.dart';
import 'package:plan_pm/pages/settings/widgets/controls/themed_outline_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu/menu_section.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class StudentInfo extends StatelessWidget {
  const StudentInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 12,
      color: AppColor.outline,
    );
    return MenuSection(
      title: l10n.academicInfoHeader,
      action: [
        ThemedOutlineButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InputPage()),
            );
          },
          label: l10n.editButton,
          icon: LucideIcons.edit3,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoText(title: l10n.facultyLabel, content: Student.faculty),
          divider,
          InfoText(title: l10n.fieldLabel, content: Student.degreeCourse),
          divider,
          InfoText(
            title: l10n.specialisationLabel,
            content: Student.specialisation,
          ),
          divider,
          InfoText(
            title: l10n.yearLabel,
            content: l10n.studyYear(Student.year ?? 0),
          ),
          divider,
          InfoText(
            title: l10n.studyModeLabel,
            content: Student.studyMode?.displayName,
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
