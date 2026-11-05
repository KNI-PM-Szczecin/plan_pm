// Strona wyboru wykładowcy — wyświetla przefiltrowaną listę wykładowców z wyszukiwarką.
// Przyjmuje gotową listę [LecturerItem] z zewnątrz i zwraca wybrany element przez [onContinue].
// „Dalej" czeka na [onContinue] ze spinnerem — wcześniej dubel tapnięcia
// uruchamiał drugie czyszczenie planu w trakcie trwającego syncu.
// Nagłówek, wyszukiwarka i lista są w jednym CustomScrollView: w poziomie
// z klawiaturą stały blok nagłówka nie mieścił się na ekranie.
import 'package:flutter/material.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/app_bottom_actions.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/pages/lecturer/widgets/lecturer_search_field.dart';
import 'package:plan_pm/pages/lecturer/widgets/lecturer_tile.dart';
import 'package:plan_pm/pages/welcome/gdpr_consent_page.dart';

class LecturerSelectionPage extends StatefulWidget {
  const LecturerSelectionPage({
    super.key,
    required this.lecturers,
    required this.onContinue,
  });

  final List<LecturerItem> lecturers;
  final Future<void> Function(LecturerItem selected) onContinue;

  @override
  State<LecturerSelectionPage> createState() => _LecturerSelectionPageState();
}

class _LecturerSelectionPageState extends State<LecturerSelectionPage> {
  final _searchController = TextEditingController();
  LecturerItem? _selected;
  String _query = '';

  /// Trwa [onContinue] (zapis + sync) — przycisk pokazuje spinner.
  bool _submitting = false;

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

  void _continue() {
    if (kDebugGdpr) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GdprConsentPage(onAccepted: _submit),
        ),
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onContinue(_selected!);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColor.groupedBackground,
      appBar: CustomAppBar(backgroundColor: AppColor.groupedBackground),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          l10n.lecturerSelectionTitle,
                          style: AppTextStyle.largeTitleEmphasized.copyWith(
                            color: AppColor.onBackground,
                          ),
                        ),
                        Text(
                          l10n.lecturerSelectionSubtitle,
                          style: AppTextStyle.subheadline.copyWith(
                            color: AppColor.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: LecturerSearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        color: AppColor.groupedSurface,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(
                            AppGroupedSection.radius,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.lecturerSearchNoResults,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.body.copyWith(
                          color: AppColor.labelSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return LecturerTile(
                          item: item,
                          isFirst: i == 0,
                          isLast: i == items.length - 1,
                          selected: _selected?.id == item.id,
                          onTap: () {
                            if (!_submitting) setState(() => _selected = item);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          AppBottomActions(
            primary: AppButton(
              label: l10n.nextButton,
              isLoading: _submitting,
              onPressed: _selected == null ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }
}
