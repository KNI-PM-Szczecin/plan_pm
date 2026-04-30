import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GroupBuilder extends StatefulWidget {
  const GroupBuilder({super.key, required this.groups});

  final Map<String, dynamic> groups;

  @override
  State<GroupBuilder> createState() => _GroupBuilderState();
}

String convertLetterToGroup(String letter, AppLocalizations l10n) {
  switch (letter.toLowerCase()) {
    case "a":
      return l10n.groupTypeAuditorium;

    case "c":
      return l10n.groupTypeClasses;

    case "l":
      return l10n.groupTypeLabs;

    default:
      return l10n.groupTypeOther;
  }
}

class _GroupBuilderState extends State<GroupBuilder> {
  late List<String> selectedGroups;

  @override
  void initState() {
    super.initState();
    selectedGroups = List.from(Student.selectedGroups ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sortowanie kategorii grup: A (Audytorium) -> C (Ćwiczenia) -> L (Laboratoria) -> Inne
    final sortedEntries = widget.groups.entries.toList()
      ..sort((a, b) {
        int getPriority(String key) {
          switch (key.toLowerCase()) {
            case 'a':
              return 0;
            case 'c':
              return 1;
            case 'l':
              return 2;
            default:
              return 3;
          }
        }

        return getPriority(a.key).compareTo(getPriority(b.key));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ...sortedEntries.map(
          (letter) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                convertLetterToGroup(letter.key, l10n),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.onBackgroundVariant,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Konfiguracja siatki: 4 elementy na rząd
                  const int crossAxisCount = 4;
                  const double spacing = 8.0;
                  // Obliczamy szerokość jednego przycisku odejmując sumę odstępów
                  final double itemWidth =
                      (constraints.maxWidth -
                          (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;

                  // Sortowanie grup: najpierw po numerze, potem alfabetycznie
                  final List<dynamic> sortedGroups = List.from(
                    letter.value as List,
                  );
                  final RegExp regExp = RegExp(r'\d+');

                  sortedGroups.sort((a, b) {
                    final String nameA = (a['short'] ?? a['long'] ?? '')
                        .toString();
                    final String nameB = (b['short'] ?? b['long'] ?? '')
                        .toString();

                    final Match? matchA = regExp.firstMatch(nameA);
                    final Match? matchB = regExp.firstMatch(nameB);

                    if (matchA != null && matchB != null) {
                      final int numA = int.parse(matchA.group(0)!);
                      final int numB = int.parse(matchB.group(0)!);
                      if (numA != numB) return numA.compareTo(numB);
                    }

                    return nameA.compareTo(nameB);
                  });

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: sortedGroups.map<Widget>((g) {
                      bool isSelected = selectedGroups.contains(g["long"]);

                      final Widget button = OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isSelected
                              ? AppColor.primary
                              : AppColor.surface,
                          foregroundColor: isSelected
                              ? AppColor.onPrimary
                              : AppColor.onSurface,
                          side: BorderSide(
                            color: isSelected
                                ? AppColor.primary
                                : AppColor.outline,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              selectedGroups.remove(g["long"]);
                            } else {
                              // Odznacz inne grupy w tej samej kategorii literowej
                              for (var other in letter.value) {
                                selectedGroups.remove(other["long"]);
                              }
                              selectedGroups.add(g["long"]);
                            }
                            Student.selectedGroups = selectedGroups;
                          });
                        },
                        child: Text(
                          g['short'] ?? g['long'] ?? '',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );

                      // Jeśli jest tylko jedna grupa, zajmuje całą szerokość, w przeciwnym razie 1/4
                      return SizedBox(
                        width: sortedGroups.length == 1
                            ? constraints.maxWidth
                            : itemWidth,
                        child: button,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
