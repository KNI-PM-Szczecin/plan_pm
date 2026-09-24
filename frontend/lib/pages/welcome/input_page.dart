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
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/states/generic_loading.dart';
import 'package:plan_pm/global/widgets/states/generic_no_resource.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';
import 'package:plan_pm/pages/welcome/widgets/button_switch.dart';
import 'package:plan_pm/pages/welcome/widgets/dropdown_menu.dart';
import 'package:plan_pm/pages/welcome/widgets/onboarding_action_bar.dart';
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

  TextEditingController facultyController = TextEditingController();
  TextEditingController degreeCourseController = TextEditingController();
  TextEditingController specialisationController = TextEditingController();

  final _backendService = BackendService();

  late Future<ProgramAvailability> _futureAvailability;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _futureAvailability = _backendService.fetchProgramAvailability();
  }

  @override
  void dispose() {
    facultyController.dispose();
    degreeCourseController.dispose();
    specialisationController.dispose();
    super.dispose();
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
      facultyController.text = "";
    }
    if (selectedFaculty.isEmpty ||
        (selectedDegreeCourse.isNotEmpty &&
            !availability
                .degreeCourses(selectedFaculty)
                .contains(selectedDegreeCourse))) {
      selectedDegreeCourse = "";
      degreeCourseController.text = "";
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
  void _autoSelectSingletons(
    ProgramAvailability availability,
    AppLocalizations l10n,
  ) {
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
        // DropdownMenu wyświetla to, co ma w kontrolerze — sam `selectedValue`
        // nie odświeży pola przy wyborze zrobionym programowo.
        specialisationController.text = _specialisationLabel(
          choices.first,
          l10n,
        );
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
    specialisationController.text = "";
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ProgramAvailability>(
      future: _futureAvailability,
      builder: (context, snapshot) {
        final availability = snapshot.data;
        final option = availability == null ? null : _resolved(availability);
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColor.background,
          appBar: CustomAppBar(
            title: l10n.studySettings,
            onBack: () {
              HapticFeedback.lightImpact();
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniCenterFloat,
          floatingActionButton: OnboardingActionBar(
            skipLabel: l10n.skipButton,
            onSkip: () {
              HapticFeedback.lightImpact();
              if (widget.isRoleSwitch) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: "Plan PM"),
                  ),
                );
              }
            },
            confirmLabel: l10n.groupSelection,
            onConfirm: (option != null && !_isSubmitting)
                ? () => _submit(option)
                : null,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                15,
                15,
                15,
                15 + OnboardingActionBar.reservedSpace(context),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      l10n.groupSelectionHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.onBackgroundVariant,
                      ),
                    ),
                    if (snapshot.hasError)
                      GenericNoResource(
                        label: l10n.unexpectedError,
                        icon: LucideIcons.wifiOff,
                        description: l10n.networkErrorDescription,
                      )
                    else if (snapshot.connectionState != ConnectionState.done)
                      GenericLoading(label: l10n.universityStructureLoading)
                    else if (availability == null || availability.isEmpty)
                      GenericNoResource(
                        label: l10n.noNews,
                        icon: LucideIcons.calendarX,
                        description: l10n.universityStructureEmpty,
                      )
                    else
                      _buildForm(availability, l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(ProgramAvailability availability, AppLocalizations l10n) {
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
    final Map<String, ProgramOption> specialisationsByLabel = {
      for (final option in specialisationOptions)
        _specialisationLabel(option, l10n): option,
    };
    final selectedSpecialisationLabel = specialisationsByLabel.entries
        .where((entry) => entry.value.specialisationKey == selectedSpecialisationKey)
        .map((entry) => entry.key)
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

    return Column(
      children: [
        const SizedBox(height: 10),
        FacultyDropDownMenu(
          controller: facultyController,
          label: l10n.facultyLabel,
          icon: LucideIcons.school,
          hint: l10n.facultyHintText,
          itemList: faculties,
          selectedValue: selectedFaculty,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            setState(() {
              if (selectedFaculty != value) {
                selectedFaculty = value!;
                _clearInvalidSelections(availability);
                _autoSelectSingletons(availability, l10n);
              }
            });
          },
        ),
        const SizedBox(height: 20),
        FacultyDropDownMenu(
          controller: degreeCourseController,
          enabled: selectedFaculty.isNotEmpty,
          label: l10n.fieldLabel,
          icon: LucideIcons.bookOpen,
          hint: l10n.fieldHintText,
          itemList: degreeCourses,
          selectedValue: selectedDegreeCourse,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            setState(() {
              if (selectedDegreeCourse != value) {
                selectedDegreeCourse = value!;
                _clearInvalidSelections(availability);
                _autoSelectSingletons(availability, l10n);
              }
            });
          },
        ),
        const SizedBox(height: 20),
        ButtonSwitch(
          label: l10n.yearLabel,
          icon: LucideIcons.graduationCap,
          buttonLabels: const ["I", "II", "III", "IV"],
          buttonAmount: kMaxYear,
          selectedIndex: selectedYear == null ? null : selectedYear! - 1,
          enabledIndices: {for (final year in availableYears) year - 1},
          onValueChanged: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              selectedYear = index + 1;
              _clearInvalidSelections(availability);
              _autoSelectSingletons(availability, l10n);
            });
          },
        ),
        const SizedBox(height: 10),
        if (selectedDegreeCourse.isNotEmpty && specialisationsByLabel.isNotEmpty)
          FacultyDropDownMenu(
            controller: specialisationController,
            label: l10n.specialisationLabel,
            icon: LucideIcons.glasses,
            hint: l10n.specialisationHintText,
            itemList: specialisationsByLabel.keys.toList(),
            selectedValue: selectedSpecialisationLabel ?? "",
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                selectedSpecialisationKey =
                    specialisationsByLabel[value]?.specialisationKey;
                _clearInvalidSelections(availability);
                _autoSelectSingletons(availability, l10n);
              });
            },
          )
        else if (selectedDegreeCourse.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Text(
              l10n.noSpecialisationForField,
              style: TextStyle(color: AppColor.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 10),
        ButtonSwitch(
          label: l10n.degreeLevelLabel,
          icon: LucideIcons.award,
          buttonLabels: [
            l10n.degreeLevelEngineering,
            l10n.degreeLevelMasters,
            l10n.degreeLevelBachelor,
          ],
          buttonAmount: kDegreeLevelCodes.length,
          selectedIndex: selectedDegreeLevel == null
              ? null
              : kDegreeLevelCodes.indexOf(selectedDegreeLevel!),
          enabledIndices: {
            for (final level in availableLevels) kDegreeLevelCodes.indexOf(level),
          },
          onValueChanged: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              selectedDegreeLevel = kDegreeLevelCodes[index];
              _clearInvalidSelections(availability);
              _autoSelectSingletons(availability, l10n);
            });
          },
        ),
        const SizedBox(height: 10),
        ButtonSwitch(
          label: l10n.typeLabel,
          icon: LucideIcons.graduationCap,
          buttonLabels: [l10n.campusButton, l10n.extramuralButton],
          buttonAmount: kProgramTypeCodes.length,
          selectedIndex: selectedProgramType == null
              ? null
              : kProgramTypeCodes.indexOf(selectedProgramType!),
          enabledIndices: {
            for (final type in availableTypes) kProgramTypeCodes.indexOf(type),
          },
          onValueChanged: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              selectedProgramType = kProgramTypeCodes[index];
              _clearInvalidSelections(availability);
              _autoSelectSingletons(availability, l10n);
            });
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
