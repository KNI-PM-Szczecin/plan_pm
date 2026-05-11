// Strona wyboru wykładowcy — wyświetla przefiltrowaną listę wykładowców z wyszukiwarką.
// Przyjmuje gotową listę [LecturerItem] z zewnątrz i zwraca wybrany element przez [onContinue].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/back_button.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/widgets/lecturer_search_field.dart';
import 'package:plan_pm/pages/lecturer/widgets/lecturer_tile.dart';

class LecturerSelectionPage extends StatefulWidget {
  const LecturerSelectionPage({
    super.key,
    required this.lecturers,
    required this.onContinue,
  });

  final List<LecturerItem> lecturers;
  final void Function(LecturerItem selected) onContinue;

  @override
  State<LecturerSelectionPage> createState() => _LecturerSelectionPageState();
}

class _LecturerSelectionPageState extends State<LecturerSelectionPage> {
  final _searchController = TextEditingController();
  LecturerItem? _selected;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LecturerItem> get _filtered {
    if (_query.isEmpty) return widget.lecturers;
    final q = _query.toLowerCase();
    return widget.lecturers
        .where((l) => l.displayName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(width: 56, child: AppBackButton()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lecturerSelectionTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColor.onBackground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.lecturerSelectionSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.onBackgroundVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LecturerSearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.lecturerSearchNoResults,
                        style: TextStyle(color: AppColor.onBackgroundVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = _filtered[i];
                        return LecturerTile(
                          item: item,
                          selected: _selected?.id == item.id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = item);
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: FilledButton(
                onPressed: _selected == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        widget.onContinue(_selected!);
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.continueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
