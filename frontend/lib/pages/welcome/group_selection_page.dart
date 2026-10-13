// Wybór grup zajęciowych studenta, pogrupowanych w sekcje przez
// [buildGroupSections]:
//   * „Grupy" — po jednym wierszu na rodzaj zajęć rocznika (audytorium,
//     ćwiczenia, laboratoria, projekt, symulator), pojedynczy wybór z menu —
//     student należy do jednej grupy; rodzaj można zostawić bez grupy,
//   * przedmioty obieralne — lista wielokrotnego wyboru z licznikiem, bo
//     obieralnych ma się kilka naraz (wcześniej jeden slot = niepełny plan).
// Po zapisaniu persystuje wybór i synchronizuje dane przez [CacheService].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_bottom_actions.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_menu_field.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/global/widgets/app_state_card.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:plan_pm/service/group_categories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

String groupKindLabel(GroupKind kind, AppLocalizations l10n) => switch (kind) {
  GroupKind.auditorium => l10n.groupTypeAuditorium,
  GroupKind.classes => l10n.groupTypeClasses,
  GroupKind.labs => l10n.groupTypeLabs,
  GroupKind.project => l10n.groupTypeProject,
  GroupKind.simulator => l10n.groupTypeSimulator,
  GroupKind.elective => l10n.groupTypeElective,
  GroupKind.other => l10n.groupTypeOther,
};

class GroupSelectionPage extends StatefulWidget {
  const GroupSelectionPage({super.key, this.isRoleSwitch = false});

  final bool isRoleSwitch;

  @override
  State<GroupSelectionPage> createState() => _GroupSelectionPageState();
}

class _GroupSelectionPageState extends State<GroupSelectionPage> {
  final BackendService _backendService = BackendService();
  late Future<List<String>> _futureGroups;
  bool _isSubmitting = false;

  /// Pełne kody wybranych grup (`KOD/PULA/ROCZNIK`) — to trafia do zapytania.
  final List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    // Celowo od zera — patrz [project_group_selection_reset_by_design]:
    // pusta lista grup = plan całego rocznika.
    Student.selectedGroups = [];
    _futureGroups = _backendService.fetchGroups();
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() => _futureGroups = _backendService.fetchGroups());
  }

  void _setSingle(GroupSection section, GroupEntry? entry) {
    HapticFeedback.lightImpact();
    setState(() {
      for (final other in section.entries) {
        _selected.remove(other.full);
      }
      if (entry != null) _selected.add(entry.full);
      Student.selectedGroups = List.of(_selected);
    });
  }

  void _toggleMulti(GroupEntry entry) {
    setState(() {
      if (!_selected.remove(entry.full)) _selected.add(entry.full);
      Student.selectedGroups = List.of(_selected);
    });
  }

  /// Zapis i przejście do home. „Pomiń" i „Zapisz" różnią się tylko tym, czy
  /// student coś zaznaczył — przy pominięciu lista jest pusta.
  Future<void> _finish() async {
    setState(() => _isSubmitting = true);
    try {
      HapticFeedback.lightImpact();
      if (widget.isRoleSwitch) {
        await AppModeManager.setMode(AppMode.student);
        sevenDayModeNotifier.value = false;
        await DatabaseService.instance.clearLectures();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("groups", Student.selectedGroups ?? []);
      await CacheService().syncNews();
      await CacheService().syncLectures();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: "Plan PM"),
        ),
        (r) => false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Ustawienia, dla których odpytaliśmy backend — pokazywane w pustym stanie,
  /// żeby student od razu zobaczył, która z nich nie pasuje (najczęściej brak
  /// specjalizacji przy roku > 1, bo od 2. roku plany są wystawiane pod nią).
  String _studySummary(AppLocalizations l10n) {
    final program = Student.specialisation?.isNotEmpty == true
        ? Student.specialisation!
        : (Student.degreeCourse ?? "");
    return [
      if (program.isNotEmpty) program,
      if (Student.year != null) "${l10n.yearText} ${Student.year}",
      if (Student.studyMode != null)
        Student.studyMode == StudyMode.stationary
            ? l10n.campusButton
            : l10n.extramuralButton,
      if (Student.degreeLevel != null && Student.degreeLevel!.isNotEmpty)
        switch (Student.degreeLevel) {
          "mgr" => l10n.degreeLevelMasters,
          "lic" => l10n.degreeLevelBachelor,
          _ => l10n.degreeLevelEngineering,
        },
    ].join(" · ");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.groupedBackground,
      appBar: CustomAppBar(title: l10n.groupSettings),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.groupSelectionHint,
                      style: AppTextStyle.subheadline.copyWith(
                        color: AppColor.labelSecondary,
                      ),
                    ),
                  ),
                  FutureBuilder(
                    future: _futureGroups,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return AppStateCard.loading(title: l10n.groupLoading);
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return AppStateCard(
                          icon: LucideIcons.wifiOff,
                          title: l10n.unexpectedError,
                          message: l10n.networkErrorDescription,
                          actionLabel: l10n.retryButton,
                          onAction: _retry,
                        );
                      }
                      final data = snapshot.data!;
                      if (data.isEmpty) {
                        return AppStateCard(
                          icon: LucideIcons.calendarX,
                          title: l10n.noGroupsAvailable,
                          message:
                              "${l10n.noGroupsAvailableSettings(_studySummary(l10n))}"
                              "\n\n${l10n.noGroupsAvailableDescription}",
                          actionLabel: Navigator.canPop(context)
                              ? l10n.changeStudyDetails
                              : null,
                          onAction: () => Navigator.pop(context),
                        );
                      }
                      // Podział na sekcje siedzi w [buildGroupSections], żeby dało
                      // się go przetestować na realnych kodach bez widżetu.
                      final sections = buildGroupSections(
                        data.map((g) => g.toString()).toList(),
                      );
                      return _buildSections(sections, l10n);
                    },
                  ),
                ],
              ),
            ),
          ),
          AppBottomActions(
            secondary: AppButton(
              label: l10n.skipButton,
              variant: AppButtonVariant.gray,
              onPressed: _isSubmitting ? null : _finish,
            ),
            primary: AppButton(
              label: l10n.save,
              isLoading: _isSubmitting,
              onPressed: _finish,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections(List<GroupSection> sections, AppLocalizations l10n) {
    final single = sections.where((s) => !s.multiSelect).toList();
    final multi = sections.where((s) => s.multiSelect).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSection.spacing,
      children: [
        if (single.isNotEmpty)
          AppSection(
            header: l10n.groupsSectionHeader,
            child: AppGroupedSection(
              children: [
                for (final section in single)
                  AppMenuField<GroupEntry>(
                    inline: true,
                    label: groupKindLabel(section.kind, l10n),
                    placeholder: l10n.groupNotSelected,
                    options: section.entries,
                    optionLabel: (e) => e.code,
                    selected: section.entries
                        .where((e) => _selected.contains(e.full))
                        .firstOrNull,
                    onSelected: (e) => _setSingle(section, e),
                    clearLabel: l10n.groupNotSelected,
                    onCleared: () => _setSingle(section, null),
                  ),
              ],
            ),
          ),
        for (final section in multi)
          AppSection(
            header: groupKindLabel(section.kind, l10n),
            headerNote: l10n.selectedCount(
              section.entries.where((e) => _selected.contains(e.full)).length,
            ),
            footer: l10n.groupTypeElectiveHint,
            child: AppGroupedSection(
              children: [
                for (final entry in section.entries)
                  AppListRow(
                    title: entry.code,
                    selected: _selected.contains(entry.full),
                    accessory: _selected.contains(entry.full)
                        ? AppListRowAccessory.checkmark
                        : AppListRowAccessory.none,
                    onTap: () => _toggleMulti(entry),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
