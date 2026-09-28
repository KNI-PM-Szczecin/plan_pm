// Formularz danych akademickich studenta — wydział, kierunek, rok, specjalizacja,
// stopień, tryb.
//
// Formularz kaskaduje po [ProgramAvailability], czyli po kombinacjach, dla
// których w bazie naprawdę są grupy. Wcześniej listy brał z samego drzewka
// struktury uczelni i dało się złożyć zestaw bez ani jednej grupy (plany od
// 2. roku są wystawiane pod nazwą specjalizacji, nie kierunku).
//
// Po zatwierdzeniu persystuje dane i przechodzi do [GroupSelectionPage].
// Zapisujemy `programName` z bazy 1:1, żeby późniejsze `.eq("program_name", …)`
// trafiało nawet gdy uczelnia trzyma nazwę z podwójną spacją.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_bottom_actions.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_menu_field.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/global/widgets/app_segmented_control.dart';
import 'package:plan_pm/global/widgets/app_state_card.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/program_availability.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kody stopni w bazie (kolumna degree_level) w kolejności przycisków w selektorze.
const List<String> kDegreeLevelCodes = ["inż.", "mgr", "lic"];

// Kody trybu studiów (kolumna program_type) w kolejności przycisków.
const List<String> kProgramTypeCodes = ["S", "N"];

// Maksymalny rok, jaki pokazuje selektor.
const int kMaxYear = 4;

class InputPage extends StatefulWidget {
  const InputPage({super.key, this.isRoleSwitch = false});

  final bool isRoleSwitch;

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String selectedFaculty = "";
  String selectedDegreeCourse = "";

  /// Klucz pozycji z listy specjalizacji ([ProgramOption.specialisationKey]),
  /// null = jeszcze nie wybrano.
  String? selectedSpecialisationKey;

  int? selectedYear;
  String? selectedDegreeLevel;
  String? selectedProgramType;

  final _backendService = BackendService();

  late Future<ProgramAvailability> _futureAvailability;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _futureAvailability = _backendService.fetchProgramAvailability();
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() {
      _futureAvailability = _backendService.fetchProgramAvailability();
    });
  }

  ProgramOption? _resolved(ProgramAvailability availability) {
    if (selectedFaculty.isEmpty ||
        selectedDegreeCourse.isEmpty ||
        selectedSpecialisationKey == null ||
        selectedYear == null ||
        selectedDegreeLevel == null ||
        selectedProgramType == null) {
      return null;
    }
    return availability.resolve(
      faculty: selectedFaculty,
      degreeCourse: selectedDegreeCourse,
      specialisationKey: selectedSpecialisationKey!,
      year: selectedYear!,
      programType: selectedProgramType!,
      degreeLevel: selectedDegreeLevel!,
    );
  }

  /// Czyści wybory, które po zmianie wyżej w kaskadzie przestały istnieć.
  /// Kolejność jest ta sama, co na ekranie: wydział → kierunek → rok →
  /// specjalizacja → stopień → tryb.
  void _clearInvalidSelections(ProgramAvailability availability) {
    if (selectedFaculty.isNotEmpty &&
        !availability.faculties().contains(selectedFaculty)) {
      selectedFaculty = "";
    }
    if (selectedFaculty.isEmpty ||
        (selectedDegreeCourse.isNotEmpty &&
            !availability
                .degreeCourses(selectedFaculty)
                .contains(selectedDegreeCourse))) {
      selectedDegreeCourse = "";
    }
    if (selectedDegreeCourse.isEmpty) {
      selectedYear = null;
      _clearSpecialisation();
      selectedDegreeLevel = null;
      selectedProgramType = null;
      return;
    }

    final years = availability.years(
      faculty: selectedFaculty,
      degreeCourse: selectedDegreeCourse,
    );
    if (selectedYear != null && !years.contains(selectedYear)) {
      selectedYear = null;
    }

    final specKeys = availability
        .specialisationChoices(
          faculty: selectedFaculty,
          degreeCourse: selectedDegreeCourse,
          year: selectedYear,
        )
        .map((option) => option.specialisationKey)
        .toSet();
    if (selectedSpecialisationKey != null &&
        !specKeys.contains(selectedSpecialisationKey)) {
      _clearSpecialisation();
    }

    final levels = availability.degreeLevels(
      faculty: selectedFaculty,
      degreeCourse: selectedDegreeCourse,
      specialisationKey: selectedSpecialisationKey,
      year: selectedYear,
    );
    if (selectedDegreeLevel != null && !levels.contains(selectedDegreeLevel)) {
      selectedDegreeLevel = null;
    }

    final types = availability.programTypes(
      faculty: selectedFaculty,
      degreeCourse: selectedDegreeCourse,
      specialisationKey: selectedSpecialisationKey,
      year: selectedYear,
      degreeLevel: selectedDegreeLevel,
    );
    if (selectedProgramType != null && !types.contains(selectedProgramType)) {
      selectedProgramType = null;
    }
  }

  /// Gdy po zawężeniu został tylko jeden wariant, wybiera go za studenta.
  /// Nie ma tu czego wybierać (alternatywy nie istnieją), a bez tego formularz
  /// wygląda na wypełniony, a przycisk dalej jest szary.
  void _autoSelectSingletons(ProgramAvailability availability) {
    if (selectedDegreeCourse.isEmpty) return;

    if (selectedYear == null) {
      final years = availability.years(
        faculty: selectedFaculty,
        degreeCourse: selectedDegreeCourse,
      );
      if (years.length == 1) selectedYear = years.first;
    }

    if (selectedSpecialisationKey == null) {
      final choices = availability.specialisationChoices(
        faculty: selectedFaculty,
        degreeCourse: selectedDegreeCourse,
        year: selectedYear,
      );
      if (choices.length == 1) {
        selectedSpecialisationKey = choices.first.specialisationKey;
      }
    }

    if (selectedDegreeLevel == null) {
      final levels = availability.degreeLevels(
        faculty: selectedFaculty,
        degreeCourse: selectedDegreeCourse,
        specialisationKey: selectedSpecialisationKey,
        year: selectedYear,
      );
      if (levels.length == 1) selectedDegreeLevel = levels.first;
    }

    if (selectedProgramType == null) {
      final types = availability.programTypes(
        faculty: selectedFaculty,
        degreeCourse: selectedDegreeCourse,
        specialisationKey: selectedSpecialisationKey,
        year: selectedYear,
        degreeLevel: selectedDegreeLevel,
      );
      if (types.length == 1) selectedProgramType = types.first;
    }
  }

  void _clearSpecialisation() {
    selectedSpecialisationKey = null;
  }

  String _specialisationLabel(ProgramOption option, AppLocalizations l10n) {
    final base = option.specialisation ?? l10n.noSpecialisationOption;
    return option.language == null ? base : "$base (${option.language})";
  }

  Future<void> _submit(ProgramOption option) async {
    setState(() => _isSubmitting = true);
    try {
      HapticFeedback.lightImpact();
      Student.faculty = option.faculty;
      // Gdy plan jest wystawiony pod kierunkiem, to jego nazwa leci do zapytania —
      // dlatego zapisujemy dokładnie `programName`, a nie etykietę z drzewka.
      Student.degreeCourse = option.specialisation == null
          ? option.programName
          : option.degreeCourse;
      Student.specialisation = option.specialisation == null
          ? null
          : option.programName;
      Student.studyMode = StudyModeExtension.fromProgramType(
        option.programType,
      );
      Student.degreeLevel = option.degreeLevel;
      Student.year = option.year;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("course", Student.course ?? "");
      await prefs.setString("faculty", Student.faculty ?? "");
      await prefs.setString("degree_course", Student.degreeCourse ?? "");
      await prefs.setString("specialisation", Student.specialisation ?? "");
      await prefs.setInt("year", option.year);
      await prefs.setString("study_mode", option.programType);
      await prefs.setString("degree_level", option.degreeLevel);
      // During lecturer → student switching the app is still in
      // lecturer mode here. Sync only after GroupSelectionPage has
      // committed the new mode, otherwise lecturer data is cached.
      if (!widget.isRoleSwitch) {
        await CacheService().syncNews();
        await CacheService().syncLectures();
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupSelectionPage(isRoleSwitch: widget.isRoleSwitch),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Każda zmiana w formularzu: zapisz wybór, wyczyść to, co przestało
  /// istnieć niżej w kaskadzie, i dobierz opcje bez alternatywy.
  void _update(ProgramAvailability availability, VoidCallback change) {
    HapticFeedback.lightImpact();
    setState(() {
      change();
      _clearInvalidSelections(availability);
      _autoSelectSingletons(availability);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ProgramAvailability>(
      future: _futureAvailability,
      builder: (context, snapshot) {
        final availability = snapshot.data;
        final option = availability == null ? null : _resolved(availability);
        return Scaffold(
          backgroundColor: AppColor.groupedBackground,
          appBar: CustomAppBar(
            title: l10n.studySettings,
            onBack: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              }
            },
          ),
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
                      if (snapshot.hasError)
                        AppStateCard(
                          icon: LucideIcons.wifiOff,
                          title: l10n.unexpectedError,
                          message: l10n.networkErrorDescription,
                          actionLabel: l10n.retryButton,
                          onAction: _retry,
                        )
                      else if (snapshot.connectionState != ConnectionState.done)
                        AppStateCard.loading(
                          title: l10n.universityStructureLoading,
                        )
                      else if (availability == null || availability.isEmpty)
                        AppStateCard(
                          icon: LucideIcons.calendarX,
                          title: l10n.noNews,
                          message: l10n.universityStructureEmpty,
                          actionLabel: l10n.retryButton,
                          onAction: _retry,
                        )
                      else
                        ..._buildForm(availability, l10n),
                    ],
                  ),
                ),
              ),
              AppBottomActions(
                secondary: AppButton(
                  label: l10n.skipButton,
                  variant: AppButtonVariant.gray,
                  onPressed: () {
                    if (widget.isRoleSwitch) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MyHomePage(title: "Plan PM"),
                        ),
                      );
                    }
                  },
                ),
                primary: AppButton(
                  label: l10n.groupSelection,
                  isLoading: _isSubmitting,
                  // Nieaktywny, dopóki dane się nie wczytają i zestaw nie jest pełny.
                  onPressed: option == null ? null : () => _submit(option),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildForm(
    ProgramAvailability availability,
    AppLocalizations l10n,
  ) {
    final faculties = availability.faculties();
    final degreeCourses = selectedFaculty.isNotEmpty
        ? availability.degreeCourses(selectedFaculty)
        : <String>[];

    final specialisationOptions = selectedDegreeCourse.isNotEmpty
        ? availability.specialisationChoices(
            faculty: selectedFaculty,
            degreeCourse: selectedDegreeCourse,
            year: selectedYear,
          )
        : <ProgramOption>[];
    final selectedSpecialisation = specialisationOptions
        .where((o) => o.specialisationKey == selectedSpecialisationKey)
        .firstOrNull;

    final availableYears = selectedDegreeCourse.isNotEmpty
        ? availability.years(
            faculty: selectedFaculty,
            degreeCourse: selectedDegreeCourse,
          )
        : <int>{};
    final availableLevels = selectedDegreeCourse.isNotEmpty
        ? availability.degreeLevels(
            faculty: selectedFaculty,
            degreeCourse: selectedDegreeCourse,
            specialisationKey: selectedSpecialisationKey,
            year: selectedYear,
          )
        : <String>{};
    final availableTypes = selectedDegreeCourse.isNotEmpty
        ? availability.programTypes(
            faculty: selectedFaculty,
            degreeCourse: selectedDegreeCourse,
            specialisationKey: selectedSpecialisationKey,
            year: selectedYear,
            degreeLevel: selectedDegreeLevel,
          )
        : <String>{};

    const yearLabels = ["I", "II", "III", "IV"];
    final levelLabels = [
      l10n.degreeLevelEngineering,
      l10n.degreeLevelMasters,
      l10n.degreeLevelBachelor,
    ];
    final typeLabels = [l10n.campusButton, l10n.extramuralButton];

    return [
      AppGroupedSection(
        children: [
          AppMenuField<String>(
            label: l10n.facultyLabel,
            placeholder: l10n.facultyHintText,
            options: faculties,
            optionLabel: (v) => v,
            selected: selectedFaculty.isEmpty ? null : selectedFaculty,
            onSelected: (value) {
              if (value == selectedFaculty) return;
              _update(availability, () => selectedFaculty = value);
            },
          ),
          AppMenuField<String>(
            label: l10n.fieldLabel,
            placeholder: l10n.fieldHintText,
            enabled: selectedFaculty.isNotEmpty,
            options: degreeCourses,
            optionLabel: (v) => v,
            selected: selectedDegreeCourse.isEmpty
                ? null
                : selectedDegreeCourse,
            onSelected: (value) {
              if (value == selectedDegreeCourse) return;
              _update(availability, () => selectedDegreeCourse = value);
            },
          ),
        ],
      ),
      // Rok stoi przed specjalizacją, bo lista specjalizacji zależy od roku
      // (od 2. roku plan jest wystawiany pod nazwą specjalizacji).
      AppSection(
        header: l10n.yearLabel,
        child: AppSegmentedControl<int>(
          segments: [
            for (var year = 1; year <= kMaxYear; year++)
              AppSegment(value: year, label: yearLabels[year - 1]),
          ],
          selected: selectedYear,
          disabled: {
            for (var year = 1; year <= kMaxYear; year++)
              if (!availableYears.contains(year)) year,
          },
          onChanged: (year) => _update(availability, () => selectedYear = year),
        ),
      ),
      if (selectedDegreeCourse.isNotEmpty)
        AppSection(
          footer: specialisationOptions.isEmpty
              ? l10n.noSpecialisationForField
              : null,
          child: AppGroupedSection(
            children: [
              AppMenuField<ProgramOption>(
                label: l10n.specialisationLabel,
                placeholder: l10n.specialisationHintText,
                options: specialisationOptions,
                optionLabel: (o) => _specialisationLabel(o, l10n),
                selected: selectedSpecialisation,
                onSelected: (o) => _update(
                  availability,
                  () => selectedSpecialisationKey = o.specialisationKey,
                ),
              ),
            ],
          ),
        ),
      AppSection(
        header: l10n.degreeLevelLabel,
        footer: l10n.unavailableOptionsHint,
        child: AppSegmentedControl<String>(
          segments: [
            for (final (i, code) in kDegreeLevelCodes.indexed)
              AppSegment(value: code, label: levelLabels[i]),
          ],
          selected: selectedDegreeLevel,
          disabled: {
            for (final code in kDegreeLevelCodes)
              if (!availableLevels.contains(code)) code,
          },
          onChanged: (code) =>
              _update(availability, () => selectedDegreeLevel = code),
        ),
      ),
      AppSection(
        header: l10n.typeLabel,
        child: AppSegmentedControl<String>(
          segments: [
            for (final (i, code) in kProgramTypeCodes.indexed)
              AppSegment(value: code, label: typeLabels[i]),
          ],
          selected: selectedProgramType,
          disabled: {
            for (final code in kProgramTypeCodes)
              if (!availableTypes.contains(code)) code,
          },
          onChanged: (code) =>
              _update(availability, () => selectedProgramType = code),
        ),
      ),
    ];
  }
}
