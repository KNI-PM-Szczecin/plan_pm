// Karta z danymi wykładowcy — imię i nazwisko z tytułem.
// Przycisk "Edytuj" pobiera listę wykładowców i otwiera [LecturerSelectionPage].
// Po wyborze zapisuje dane, synchronizuje plan i wraca do ekranu głównego.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/pages/settings/widgets/controls/themed_outline_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu/menu_section.dart';
import 'package:plan_pm/pages/settings/widgets/info/info_text.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LecturerInfo extends StatefulWidget {
  const LecturerInfo({super.key});

  @override
  State<LecturerInfo> createState() => _LecturerInfoState();
}

class _LecturerInfoState extends State<LecturerInfo> {
  Future<void> _editLecturer() async {
    HapticFeedback.lightImpact();
    final lecturers = await BackendService().fetchTeachers();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerSelectionPage(
          lecturers: lecturers,
          onContinue: (LecturerItem selected) async {
            Lecturer.id = selected.id;
            Lecturer.name = selected.name;
            Lecturer.title = selected.title;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('lecturer_id', selected.id);
            await prefs.setString('lecturer_name', selected.name);
            if (selected.title != null) {
              await prefs.setString('lecturer_title', selected.title!);
            } else {
              await prefs.remove('lecturer_title');
            }

            await DatabaseService.instance.clearLectures();
            await CacheService().syncLectures();

            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuSection(
      title: l10n.academicInfoHeader,
      action: [
        ThemedOutlineButton(
          onPressed: _editLecturer,
          label: l10n.editButton,
          icon: LucideIcons.edit3,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoText(title: l10n.lecturerLabel, content: Lecturer.displayName),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
