import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/global/widgets/generic_loading.dart';
import 'package:plan_pm/global/widgets/generic_no_resource.dart';
import 'package:plan_pm/main.dart';
import 'package:plan_pm/pages/welcome/group_selection_page.dart';
import 'package:plan_pm/pages/welcome/widgets/button_switch.dart';
import 'package:plan_pm/pages/welcome/widgets/dropdown_menu.dart';
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

  TextEditingController facultyController = TextEditingController();
  TextEditingController degreeCourseController = TextEditingController();
  TextEditingController specialisationController = TextEditingController();

  final _backendService = BackendService();

  late Future<UniversityData> _futureUniversityStructure;

  @override
  void initState() {
    super.initState();
    _futureUniversityStructure = _backendService.fetchStructure().then((data) {
      return data;
    });
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColor.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
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
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColor.onBackgroundVariant,
          ),
        ),
        backgroundColor: AppColor.background,
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
        title: Text(
          l10n.studySettings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColor.surface,
                  ),

                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColor.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MyHomePage(title: "Plan PM"),
                        ),
                      );
                    },
                    child: Text(
                      l10n.skipButton,
                      style: TextStyle(color: AppColor.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    disabledBackgroundColor: AppColor.surface,
                    foregroundColor: AppColor.onPrimary,
                    disabledForegroundColor: AppColor.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(16),
                    ),
                  ),
                  onPressed:
                      (selectedYear <= 2
                          ? selectedFaculty != "" &&
                                selectedDegreeCourse != "" &&
                                selectedYear != 0 &&
                                selectedTerm != null
                          : selectedFaculty != "" &&
                                selectedDegreeCourse != "" &&
                                selectedYear >= 2 &&
                                selectedTerm != null)
                      ? () async {
                          HapticFeedback.lightImpact();
                          Student.degreeCourse = selectedDegreeCourse != ""
                              ? selectedDegreeCourse
                              : null;
                          Student.faculty = selectedFaculty != ""
                              ? selectedFaculty
                              : null;
                          Student.specialisation = selectedSpecialisation != ""
                              ? selectedSpecialisation
                              : null;
                          Student.term = selectedTerm == 1
                              ? "Stacjonarne"
                              : "Niestacjonarne";
                          Student.year = selectedYear;

                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                          await prefs.setString("course", Student.course ?? "");
                          await prefs.setString(
                            "faculty",
                            Student.faculty ?? "",
                          );
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
                            "term",
                            selectedTerm == 1
                                ? "Stacjonarne"
                                : "Niestacjonarne",
                          );
                          final CacheService cacheService = CacheService();
                          await cacheService.syncNews();
                          await cacheService.syncLectures();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupSelectionPage(),
                            ),
                          );
                        }
                      : null,
                  child: Text(l10n.groupSelection),
                ),
              ),
            ),
          ],
        ),
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
                        icon: LucideIcons.bug,
                        description: snapshot.error.toString(),
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

                    final List<String> degreeCourses = selectedFaculty != ""
                        ? facultiesData[selectedFaculty]!.keys.toList()
                        : <String>[];

                    final List<String> specialisations =
                        selectedDegreeCourse != ""
                        ? facultiesData[selectedFaculty]![selectedDegreeCourse]!
                        : <String>[];

                    return Column(
                      children: [
                        SizedBox(height: 10),
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
                        SizedBox(height: 20),
                        FacultyDropDownMenu(
                          controller: degreeCourseController,
                          enabled: selectedFaculty == "" ? false : true,
                          label: l10n.fieldLabel,
                          icon: LucideIcons.bookOpen,
                          hint: l10n.fieldHintText,
                          itemList: selectedFaculty.isNotEmpty
                              ? degreeCourses
                              : [],
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
                        SizedBox(height: 20),
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
                        SizedBox(height: 10),
                        if (selectedFaculty.isNotEmpty &&
                            selectedDegreeCourse.isNotEmpty &&
                            specialisations.isNotEmpty)
                          FacultyDropDownMenu(
                            controller: specialisationController,
                            enabled: true,
                            label: l10n.specialisationLabel,
                            icon: LucideIcons.glasses,
                            hint: l10n.specialisationHintText,
                            itemList: specialisations,
                            selectedValue: selectedSpecialisation,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                selectedSpecialisation = value!;
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
                        SizedBox(height: 10),
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

                        SizedBox(height: 20),
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
