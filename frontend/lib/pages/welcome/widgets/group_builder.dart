// Siatka przycisków grup, pogrupowana w sekcje przez [buildGroupSections].
//
// W sekcjach rocznika (audytorium, ćwiczenia, laboratoria, projekt, symulator)
// obowiązuje pojedynczy wybór — student należy do jednej grupy. Sekcja
// przedmiotów obieralnych jest wielokrotnego wyboru, bo obieralnych ma się kilka
// naraz; wcześniej wszystko od "P" wpadało do jednego worka z jednym slotem i
// plan wychodził niepełny (trzy zgłoszenia od studentów WIET).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/service/group_categories.dart';

class GroupBuilder extends StatefulWidget {
  const GroupBuilder({super.key, required this.sections});

  final List<GroupSection> sections;

  @override
  State<GroupBuilder> createState() => _GroupBuilderState();
}

String groupKindLabel(GroupKind kind, AppLocalizations l10n) =>
    switch (kind) {
      GroupKind.auditorium => l10n.groupTypeAuditorium,
      GroupKind.classes => l10n.groupTypeClasses,
      GroupKind.labs => l10n.groupTypeLabs,
      GroupKind.project => l10n.groupTypeProject,
      GroupKind.simulator => l10n.groupTypeSimulator,
      GroupKind.elective => l10n.groupTypeElective,
      GroupKind.other => l10n.groupTypeOther,
    };

class _GroupBuilderState extends State<GroupBuilder> {
  late List<String> selectedGroups;

  @override
  void initState() {
    super.initState();
    selectedGroups = List.from(Student.selectedGroups ?? []);
  }

  void _toggle(GroupSection section, GroupEntry entry) {
    HapticFeedback.lightImpact();
    setState(() {
      if (selectedGroups.contains(entry.full)) {
        selectedGroups.remove(entry.full);
      } else {
        if (!section.multiSelect) {
          // Pojedynczy wybór: odznacz pozostałe grupy tej sekcji.
          for (final other in section.entries) {
            selectedGroups.remove(other.full);
          }
        }
        selectedGroups.add(entry.full);
      }
      Student.selectedGroups = selectedGroups;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        for (final section in widget.sections)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Text(
                    groupKindLabel(section.kind, l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.onBackgroundVariant,
                    ),
                  ),
                  if (section.multiSelect) ...[
                    const SizedBox(width: 6),
                    Text(
                      "· ${l10n.groupTypeElectiveHint}",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
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

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: section.entries.map<Widget>((entry) {
                      final bool isSelected = selectedGroups.contains(
                        entry.full,
                      );

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
                        onPressed: () => _toggle(section, entry),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.code,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );

                      // Jeśli jest tylko jedna grupa, zajmuje całą szerokość,
                      // w przeciwnym razie 1/4.
                      return SizedBox(
                        width: section.entries.length == 1
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
      ],
    );
  }
}
