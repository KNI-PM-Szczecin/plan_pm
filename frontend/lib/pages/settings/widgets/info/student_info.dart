// Sekcja z danymi akademickimi studenta — wydział, kierunek, specjalizacja, rok, tryb studiów.
// Akcja "Edytuj" otwiera [InputPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class StudentInfo extends StatelessWidget {
  const StudentInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (l10n.facultyLabel, Student.faculty),
      (l10n.fieldLabel, Student.degreeCourse),
      (l10n.specialisationLabel, Student.specialisation),
      (l10n.yearLabel, l10n.studyYear(Student.year ?? 0)),
      (
        l10n.studyModeLabel,
        // StudyMode.displayName jest zaszyte po polsku (służy logom), więc
        // na ekranie bierzemy tłumaczenie — inaczej UA/EN widzą "Stacjonarne".
        switch (Student.studyMode) {
          StudyMode.stationary => l10n.campusButton,
          StudyMode.notStationary => l10n.extramuralButton,
          null => null,
        },
      ),
    ];
    return AppSection(
      header: l10n.academicInfoHeader,
      actionLabel: l10n.editButton,
      onAction: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InputPage()),
        );
      },
      child: AppGroupedSection(
        children: [
          for (final (label, value) in rows)
            AppListRow(
              title: label,
              value: (value == null || value.isEmpty) ? l10n.dataNaN : value,
            ),
        ],
      ),
    );
  }
}
