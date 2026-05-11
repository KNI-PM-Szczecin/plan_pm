// Wybór roli przy onboardingu — Student lub Wykładowca.
// Ścieżka studenta: ustawia tryb → [InputPage].
// Ścieżka wykładowcy: pobiera listę, persystuje dane, synchronizuje zajęcia → home.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/pages/welcome/widgets/role_illustration.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const RoleIllustration(),
              const SizedBox(height: 40),
              Text(
                l10n.roleSelectionTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColor.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.roleSelectionSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColor.onBackgroundVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await AppModeManager.setMode(AppMode.student);
                  sevenDayModeNotifier.value = false;
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InputPage()),
                  );
                },
                icon: const Icon(LucideIcons.graduationCap),
                label: Text(l10n.roleStudentButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final lecturers = await BackendService().fetchTeachers();
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LecturerSelectionPage(
                        lecturers: lecturers,
                        onContinue: (LecturerItem selected) async {
                          Lecturer.id = selected.id;
                          Lecturer.name = selected.name;
                          Lecturer.title = selected.title;

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('lecturer_id', selected.id);
                          await prefs.setString('lecturer_name', selected.name);
                          if (selected.title != null) {
                            await prefs.setString(
                              'lecturer_title',
                              selected.title!,
                            );
                          } else {
                            await prefs.remove('lecturer_title');
                          }
                          await prefs.setBool('skip_welcome', true);

                          await AppModeManager.setMode(AppMode.lecturer);
                          sevenDayModeNotifier.value = true;

                          await DatabaseService.instance.clearLectures();
                          await CacheService().syncLectures();
                          await CacheService().syncNews();

                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (_) => false);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.monitor),
                label: Text(l10n.roleLecturerButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColor.surface,
                  foregroundColor: AppColor.onSurface,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}


