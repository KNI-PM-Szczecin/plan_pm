import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/lecturer.dart';
import 'package:plan_pm/global/widgets/themed_outline_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu_section.dart';
import 'package:plan_pm/pages/settings/widgets/student_info.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LecturerInfo extends StatelessWidget {
  const LecturerInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuSection(
      title: l10n.academicInfoHeader,
      action: [
        SizedBox(
          height: 35,
          child: ThemedOutlineButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final lecturers = await BackendService().fetchTeachers();
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LecturerSelectionPage(
                    lecturers: lecturers,
                    onContinue: (selected) => Navigator.pop(context),
                  ),
                ),
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
          InfoText(
            title: l10n.lecturerLabel,
            content: Lecturer.displayName,
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
