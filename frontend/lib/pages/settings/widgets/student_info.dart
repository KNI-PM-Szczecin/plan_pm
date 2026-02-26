import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/global/widgets/themed_outline_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu_section.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class StudentInfo extends StatelessWidget {
  const StudentInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuSection(
      title: l10n.academicInfoHeader,
      action: [
        SizedBox(
          height: 35,
          child: ThemedOutlineButton(
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
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoText(title: l10n.facultyLabel, content: Student.faculty),
          Divider(height: 1, thickness: 1, indent: 12, color: AppColor.outline),
          InfoText(title: l10n.fieldLabel, content: Student.degreeCourse),
          Divider(height: 1, thickness: 1, indent: 12, color: AppColor.outline),
          InfoText(
            title: l10n.specialisationLabel,
            content: Student.specialisation,
          ),
          Divider(height: 1, thickness: 1, indent: 12, color: AppColor.outline),
          InfoText(
            title: l10n.yearLabel,
            content: l10n.studyYear(Student.year ?? 0),
          ),
          Divider(height: 1, thickness: 1, indent: 12, color: AppColor.outline),
          InfoText(title: l10n.studyModeLabel, content: Student.term),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}

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
