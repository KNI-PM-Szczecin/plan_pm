// Wspólna ścieżka wyboru wykładowcy. Trzy wejścia — onboarding
// ([RoleSelectionPage]), zmiana roli w ustawieniach ([RoleInfo]) i „Edytuj"
// u wykładowcy ([LecturerInfo]) — robiły to samo w trzech kopiach i bez
// obsługi błędów: offline tap nic nie robił, a wyjątek z syncu leciał w górę
// już po przełączeniu trybu i wyczyszczeniu planu.
import 'package:flutter/material.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pobiera listę wykładowców. Przy błędzie (brak sieci, backend) pokazuje
/// snackbar i zwraca `null` — wołający po prostu nie otwiera ekranu wyboru.
Future<List<LecturerItem>?> loadLecturers(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    return await BackendService().fetchTeachers();
  } catch (error, stackTrace) {
    AppLogger.e("[LECTURER] fetchTeachers failed", error, stackTrace);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.networkErrorDescription)),
    );
    return null;
  }
}

/// Zapisuje wybranego wykładowcę, przełącza tryb (tryb 7-dniowy włączony),
/// czyści plan i synchronizuje OBA cache (patrz CLAUDE.md), po czym wraca na
/// ekran główny. Porażka syncu nie cofa wyboru — dane są już w prefs, więc
/// pull-to-refresh dociągnie plan; użytkownik dostaje snackbar.
Future<void> applyLecturerSelection(
  BuildContext context,
  LecturerItem selected,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);

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

  try {
    await DatabaseService.instance.clearLectures();
    await CacheService().syncLectures();
    await CacheService().syncNews();
  } catch (error, stackTrace) {
    AppLogger.e("[LECTURER] sync after selection failed", error, stackTrace);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.unexpectedError)));
  }

  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
}
