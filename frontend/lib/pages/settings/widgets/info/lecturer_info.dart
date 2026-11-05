// Sekcja z danymi wykładowcy — imię i nazwisko z tytułem.
// Akcja "Edytuj" pobiera listę wykładowców i otwiera [LecturerSelectionPage];
// wybór zapisuje i synchronizuje [applyLecturerSelection].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/utils/lecturer_flow.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LecturerInfo extends StatefulWidget {
  const LecturerInfo({super.key});

  @override
  State<LecturerInfo> createState() => _LecturerInfoState();
}

class _LecturerInfoState extends State<LecturerInfo> {
  /// Trwa pobieranie listy wykładowców — kolejne tapnięcia „Edytuj" ignorujemy.
  bool _loadingLecturers = false;

  Future<void> _editLecturer() async {
    if (_loadingLecturers) return;
    HapticFeedback.lightImpact();
    _loadingLecturers = true;
    final lecturers = await loadLecturers(context);
    _loadingLecturers = false;
    if (lecturers == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerSelectionPage(
          lecturers: lecturers,
          onContinue: (selected) => applyLecturerSelection(context, selected),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSection(
      header: l10n.lecturerInfoHeader,
      actionLabel: l10n.editButton,
      onAction: _editLecturer,
      child: AppGroupedSection(
        children: [
          AppListRow(
            title: l10n.lecturerLabel,
            value: Lecturer.displayName ?? l10n.dataNaN,
          ),
        ],
      ),
    );
  }
}
