// Formularz danych akademickich studenta — wydział, kierunek, specjalizacja, rok, tryb, stopień.
// Walidacja: wszystkie pola wymagane oprócz specjalizacji (opcjonalna dla roku ≤ 2).
// Po zatwierdzeniu persystuje dane i przechodzi do [GroupSelectionPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/standard_app_bar.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

typedef UniversityData = Map<String, Map<String, List<String>>>;

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String selectedFaculty = "";
  String selectedDegreeCourse = "";
  String selectedSpecialisation = "";

  int selectedYear = 0;
  int? selectedTerm;
  int? selectedDegreeLevel;

  TextEditingController facultyController = TextEditingController();
  TextEditingController degreeCourseController = TextEditingController();
  TextEditingController specialisationController = TextEditingController();

  final _backendService = BackendService();

  late Future<UniversityData> _futureUniversityStructure;

  // Formularz jest gotowy gdy wybrano wydział, kierunek, rok (!=0), tryb i stopień.
  // Specjalizacja jest opcjonalna — pojawia się jeśli backend ją zwraca.
  bool get _canProceed =>
      selectedFaculty.isNotEmpty &&
      selectedDegreeCourse.isNotEmpty &&
      selectedYear != 0 &&
      selectedTerm != null &&
      selectedDegreeLevel != null;

  @override
  void initState() {
    super.initState();
    _futureUniversityStructure = _backendService.fetchStructure();
  }

  @override
  void dispose() {
    facultyController.dispose();
    degreeCourseController.dispose();
    specialisationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noSpecialisationOption = l10n.noSpecialisationOption;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColor.background,
      appBar: StandardAppBar(
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: "Plan PM"),
            ),
          );
        },
        confirmLabel: l10n.groupSelection,
        onConfirm: _canProceed
            ? () async {
                HapticFeedback.lightImpact();
                Student.degreeCourse = selectedDegreeCourse.isNotEmpty
                    ? selectedDegreeCourse
                    : null;
                Student.faculty = selectedFaculty.isNotEmpty
                    ? selectedFaculty
                    : null;
                Student.specialisation = selectedSpecialisation.isNotEmpty
                    ? selectedSpecialisation
                    : null;
                Student.studyMode = selectedTerm == 1
                    ? StudyMode.stationary
                    : StudyMode.notStationary;
                Student.degreeLevel = selectedDegreeLevel == 1 ? "inż." : "mgr";
                Student.year = selectedYear;

                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                await prefs.setString("course", Student.course ?? "");
                await prefs.setString("faculty", Student.faculty ?? "");
                await prefs.setString(
                  "degree_course",
                  Student.degreeCourse ?? "",
                );
                await prefs.setString(
                  "specialisation",
                  Student.specialisation ?? "",
                );
                await prefs.setInt("year", selectedYear);
                await prefs.setString(
                  "study_mode",
                  Student.studyMode?.programType ?? "S",
                );
                await prefs.setString(
                  "degree_level",
                  selectedDegreeLevel == 1 ? "inż." : "mgr",
                );
                await CacheService().syncNews();
                await CacheService().syncLectures();
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupSelectionPage(),
                  ),
                );
              }
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 15,
            top: 15,
            right: 15,
            bottom: 80,
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
                FutureBuilder(
                  future: _futureUniversityStructure,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return GenericNoResource(
                        label: l10n.unexpectedError,
                        icon: LucideIcons.wifiOff,
                        description: l10n.networkErrorDescription,
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return GenericLoading(
                        label: l10n.universityStructureLoading,
                      );
                    }
                    if (snapshot.data != null && snapshot.data!.isEmpty) {
                      return GenericNoResource(
                        label: l10n.noNews,
                        icon: LucideIcons.calendarX,
                        description: l10n.universityStructureEmpty,
                      );
                    }
                    final facultiesData = snapshot.data!;
                    final List<String> faculties = facultiesData.keys.toList();

                    final List<String> degreeCourses = selectedFaculty.isNotEmpty
                        ? facultiesData[selectedFaculty]!.keys.toList()
                        : <String>[];

                    final List<String> specialisations =
                        selectedDegreeCourse.isNotEmpty
                        ? [
                            noSpecialisationOption,
                            ...facultiesData[selectedFaculty]![selectedDegreeCourse]!,
                          ]
                        : <String>[];

                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        FacultyDropDownMenu(
                          controller: facultyController,
                          label: l10n.facultyLabel,
                          icon: LucideIcons.school,
                          hint: l10n.facultyHintText,
                          itemList: faculties,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (selectedFaculty != value) {
                                selectedFaculty = value!;
                                selectedDegreeCourse = "";
                                selectedSpecialisation = "";
                                degreeCourseController.text = "";
                                specialisationController.text = "";
                              }
                            });
                          },
                          selectedValue: selectedFaculty,
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
                                selectedSpecialisation = "";
                                specialisationController.text = "";
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        ButtonSwitch(
                          onValueChanged: (year) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedYear = year + 1;
                              selectedSpecialisation = "";
                              specialisationController.text = "";
                            });
                          },
                          buttonLabels: ["I", "II", "III", "IV"],
                          buttonAmount: 4,
                          icon: LucideIcons.graduationCap,
                          label: l10n.yearLabel,
                        ),
                        const SizedBox(height: 10),
                        if (selectedFaculty.isNotEmpty &&
                            selectedDegreeCourse.isNotEmpty &&
                            specialisations.isNotEmpty)
                          FacultyDropDownMenu(
                            controller: specialisationController,
                            label: l10n.specialisationLabel,
                            icon: LucideIcons.glasses,
                            hint: l10n.specialisationHintText,
                            itemList: specialisations,
                            selectedValue: selectedSpecialisation,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                selectedSpecialisation =
                                    value == noSpecialisationOption ? "" : value!;
                              });
                            },
                          )
                        else if (selectedFaculty.isNotEmpty &&
                            selectedDegreeCourse.isNotEmpty &&
                            specialisations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              l10n.noSpecialisationForField,
                              style: TextStyle(
                                color: AppColor.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        ButtonSwitch(
                          onValueChanged: (degreeLevel) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedDegreeLevel = degreeLevel + 1;
                            });
                          },
                          buttonLabels: [
                            l10n.degreeLevelEngineering,
                            l10n.degreeLevelMasters,
                          ],
                          buttonAmount: 2,
                          icon: LucideIcons.award,
                          label: l10n.degreeLevelLabel,
                        ),
                        const SizedBox(height: 10),
                        ButtonSwitch(
                          onValueChanged: (term) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedTerm = term + 1;
                            });
                          },
                          buttonLabels: [
                            l10n.campusButton,
                            l10n.extramuralButton,
                          ],
                          buttonAmount: 2,
                          icon: LucideIcons.graduationCap,
                          label: l10n.typeLabel,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
