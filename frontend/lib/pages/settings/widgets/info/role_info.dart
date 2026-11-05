// Przełącznik roli użytkownika (Student / Wykładowca) — segmented control.
// Wykładowca → student otwiera InputPage(isRoleSwitch), student → wykładowca
// LecturerSelectionPage; tryb zmienia się dopiero po zakończeniu tamtego flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/utils/lecturer_flow.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/global/widgets/app_segmented_control.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/global/utils/routing.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';

class RoleInfo extends StatefulWidget {
  const RoleInfo({super.key});

  @override
  State<RoleInfo> createState() => _RoleInfoState();
}

class _RoleInfoState extends State<RoleInfo> {
  /// Trwa pobieranie listy wykładowców — kolejne tapnięcia segmentu ignorujemy.
  bool _loadingLecturers = false;

  Future<void> _switchToStudent() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.push(
      context,
      appRoute((_) => const InputPage(isRoleSwitch: true)),
    );
  }

  Future<void> _switchToLecturer() async {
    if (_loadingLecturers) return;
    HapticFeedback.lightImpact();
    _loadingLecturers = true;
    final lecturers = await loadLecturers(context);
    _loadingLecturers = false;
    if (lecturers == null || !mounted) return;
    Navigator.push(
      context,
      appRoute(
        (_) => LecturerSelectionPage(
          lecturers: lecturers,
          onContinue: (selected) => applyLecturerSelection(context, selected),
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
