// Przełącznik roli użytkownika (Student / Wykładowca) — segmented control.
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
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLecturer = AppModeManager.current == AppMode.lecturer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTabColor = isDark ? const Color(0xFF3A3A3C) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.roleSectionTitle.toUpperCase(),
          style: TextStyle(
            color: AppColor.onBackgroundVariant,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _Segment(
                icon: LucideIcons.graduationCap,
                label: l10n.roleStudentViewTitle,
                isActive: !isLecturer,
                activeTabColor: activeTabColor,
                onTap: isLecturer ? _switchToStudent : null,
              ),
              _Segment(
                icon: LucideIcons.briefcase,
                label: l10n.roleLecturerViewTitle,
                isActive: isLecturer,
                activeTabColor: activeTabColor,
                onTap: isLecturer ? null : _switchToLecturer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            isLecturer ? l10n.roleViewingAsLecturer : l10n.roleViewingAsStudent,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColor.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeTabColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeTabColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeTabColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColor.primary : AppColor.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColor.onSurface
                      : AppColor.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
