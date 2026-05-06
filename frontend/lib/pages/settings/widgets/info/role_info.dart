// Przełącznik roli użytkownika (Student / Wykładowca).
// Zmiana na wykładowcę wymaga wyboru osoby, zapisu do SharedPreferences i synchronizacji zajęć.
// [_RoleTile] to lokalny widżet kafelka — 2 użycia w jednym pliku, nie warto wynosić.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/lecturer/lecturer_selection_page.dart';
import 'package:plan_pm/pages/settings/widgets/menu/menu_section.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleInfo extends StatefulWidget {
  const RoleInfo({super.key});

  @override
  State<RoleInfo> createState() => _RoleInfoState();
}

class _RoleInfoState extends State<RoleInfo> {
  Future<void> _switchToStudent() async {
    HapticFeedback.lightImpact();
    await AppModeManager.setMode(AppMode.student);
    sevenDayModeNotifier.value = false;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InputPage()),
    );
  }

  Future<void> _switchToLecturer() async {
    HapticFeedback.lightImpact();
    final lecturers = await BackendService().fetchTeachers();
    if (!mounted) return;
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
            await CacheService().syncLectures();

            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLecturer = AppModeManager.current == AppMode.lecturer;

    return MenuSection(
      title: l10n.roleSectionTitle,
      child: Column(
        children: [
          _RoleTile(
            icon: LucideIcons.graduationCap,
            title: l10n.roleStudentViewTitle,
            subtitle: isLecturer
                ? l10n.roleStudentViewSubtitle
                : l10n.roleCurrentlyActive,
            isActive: !isLecturer,
            onTap: isLecturer ? _switchToStudent : null,
          ),
          Divider(height: 1, color: AppColor.outline),
          _RoleTile(
            icon: LucideIcons.briefcase,
            title: l10n.roleLecturerViewTitle,
            subtitle: isLecturer
                ? l10n.roleCurrentlyActive
                : l10n.roleLecturerViewSubtitle,
            isActive: isLecturer,
            onTap: isLecturer ? null : _switchToLecturer,
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isActive
                    ? AppColor.primary.withValues(alpha: 0.18)
                    : AppColor.onSurface.withValues(alpha: 0.08),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColor.primary : AppColor.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColor.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColor.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isActive ? LucideIcons.check : LucideIcons.arrowLeftRight,
                color: isActive ? AppColor.primary : AppColor.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
