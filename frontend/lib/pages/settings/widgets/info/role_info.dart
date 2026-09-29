// Przełącznik roli użytkownika (Student / Wykładowca) — segmented control.
// Wykładowca → student otwiera InputPage(isRoleSwitch), student → wykładowca
// LecturerSelectionPage; tryb zmienia się dopiero po zakończeniu tamtego flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/global/widgets/app_segmented_control.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/global/utils/routing.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleInfo extends StatefulWidget {
  const RoleInfo({super.key});

  @override
  State<RoleInfo> createState() => _RoleInfoState();
}

class _RoleInfoState extends State<RoleInfo> {
  Future<void> _switchToStudent() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.push(
      context,
      appRoute((_) => const InputPage(isRoleSwitch: true)),
    );
  }

  Future<void> _switchToLecturer() async {
    HapticFeedback.lightImpact();
    final lecturers = await BackendService().fetchTeachers();
    if (!mounted) return;
    Navigator.push(
      context,
      appRoute(
        (_) => LecturerSelectionPage(
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
            await prefs.setBool('skip_welcome', true);

            await AppModeManager.setMode(AppMode.lecturer);
            sevenDayModeNotifier.value = true;

            await DatabaseService.instance.clearLectures();
            await CacheService().syncLectures();
            await CacheService().syncNews();

            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLecturer = AppModeManager.current == AppMode.lecturer;

    return AppSection(
      header: l10n.roleSectionTitle,
      footer: isLecturer ? l10n.roleViewingAsLecturer : l10n.roleViewingAsStudent,
      // Zaznaczenie zmienia się dopiero po przejściu przełączania roli —
      // tryb zmienia się w GroupSelectionPage / po wyborze wykładowcy.
      child: AppSegmentedControl<AppMode>(
        height: 34,
        segments: [
          AppSegment(value: AppMode.student, label: l10n.roleStudentViewTitle),
          AppSegment(value: AppMode.lecturer, label: l10n.roleLecturerViewTitle),
        ],
        selected: AppModeManager.current,
        onChanged: (mode) =>
            mode == AppMode.student ? _switchToStudent() : _switchToLecturer(),
      ),
    );
  }
}
