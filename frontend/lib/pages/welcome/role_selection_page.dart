import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/app_mode.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/lecturer.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/global/notifiers.dart';
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
              _RoleIllustration(),
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
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                            await prefs.setString('lecturer_title', selected.title!);
                          } else {
                            await prefs.remove('lecturer_title');
                          }
                          await prefs.setBool('skip_welcome', true);

                          await AppModeManager.setMode(AppMode.lecturer);
                          sevenDayModeNotifier.value = true;

                          await DatabaseService.instance.clearLectures();
                          final cacheService = CacheService();
                          await cacheService.syncLectures();

                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/home',
                            (_) => false,
                          );
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
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _RoleIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // karta z tyłu (lekko obrócona w prawo)
          Transform.translate(
            offset: const Offset(20, -8),
            child: Transform.rotate(
              angle: 0.12,
              child: _RoleCard(icon: LucideIcons.bookOpen),
            ),
          ),
          // karta z przodu (lekko obrócona w lewo)
          Transform.translate(
            offset: const Offset(-18, 8),
            child: Transform.rotate(
              angle: -0.08,
              child: _RoleCard(icon: LucideIcons.graduationCap),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 30),
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 38,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
