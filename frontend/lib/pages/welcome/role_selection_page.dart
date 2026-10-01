// Wybór roli przy onboardingu — lista Student / Wykładowca i przycisk „Dalej".
// Ścieżka studenta: ustawia tryb → [InputPage].
// Ścieżka wykładowcy: pobiera listę, persystuje dane, synchronizuje zajęcia → home.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_hero_icon.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_radio_indicator.dart';
import 'package:plan_pm/global/widgets/app_screen_header.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AppMode _selected = AppMode.student;

  /// Trwa pobieranie listy wykładowców — przycisk pokazuje spinner.
  bool _loading = false;

  IconData _iconFor(AppMode mode) =>
      mode == AppMode.student ? LucideIcons.graduationCap : LucideIcons.monitor;

  Color _colorFor(AppMode mode) =>
      mode == AppMode.student ? AppColor.systemBlue : AppColor.systemIndigo;

  Future<void> _continue() async {
    if (_selected == AppMode.student) {
      await AppModeManager.setMode(AppMode.student);
      sevenDayModeNotifier.value = false;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InputPage()),
      );
      return;
    }

    setState(() => _loading = true);
    final List<LecturerItem> lecturers;
    try {
      lecturers = await BackendService().fetchTeachers();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerSelectionPage(
          lecturers: lecturers,
          onContinue: _onLecturerSelected,
        ),
      ),
    );
  }

  Future<void> _onLecturerSelected(LecturerItem selected) async {
    Lecturer.id = selected.id;
    Lecturer.name = selected.name;
    Lecturer.title = selected.title;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lecturer_id', selected.id);
    await prefs.setString('lecturer_name', selected.name);
    if (selected.title != null) {
      await prefs.setString('lecturer_title', selected.title!);
    } else {
      await prefs.remove('lecturer_title');
    }
    await prefs.setBool('skip_welcome', true);

    await AppModeManager.setMode(AppMode.lecturer);
    sevenDayModeNotifier.value = true;

    await DatabaseService.instance.clearLectures();
    await CacheService().syncLectures();
    await CacheService().syncNews();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  Widget _roleRow(AppMode mode, String title, String subtitle) {
    final isSelected = _selected == mode;
    return AppListRow(
      title: title,
      subtitle: subtitle,
      selected: isSelected,
      leading: AppIconBadge(
        icon: _iconFor(mode),
        color: _colorFor(mode),
        size: 36,
      ),
      trailing: AppRadioIndicator(selected: isSelected),
      onTap: _loading ? null : () => setState(() => _selected = mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppScreenHeader(
                          leading: AppHeroIcon(
                            icon: _iconFor(_selected),
                            color: _colorFor(_selected),
                          ),
                          title: l10n.roleSelectionTitle,
                          subtitle: l10n.roleSelectionSubtitle,
                        ),
                        const SizedBox(height: 32),
                        AppGroupedSection(
                          children: [
                            _roleRow(
                              AppMode.student,
                              l10n.roleStudentButton,
                              l10n.roleStudentSubtitle,
                            ),
                            _roleRow(
                              AppMode.lecturer,
                              l10n.roleLecturerButton,
                              l10n.roleLecturerSubtitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppButton(
                  label: l10n.nextButton,
                  isLoading: _loading,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
