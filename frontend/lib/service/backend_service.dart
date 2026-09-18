import 'package:intl/intl.dart';
// import 'dart:developer' as developer;
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/api/models/announcement_model.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:plan_pm/service/program_availability.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:plan_pm/global/utils/logger.dart';

class BackendService {
  static final BackendService _backendService = BackendService._internal();

  factory BackendService() {
    return _backendService;
  }

  BackendService._internal();

  void messToText(List<Map<String, dynamic>> response) {
    for (final value in response) {
      AppLogger.d(
        "${value["group"]}|${DateFormat.EEEE().format(DateTime.parse(value["start_time"]))}|${value["start_time"]} - ${value["end_time"]}, Subject: ${value["subject"]}, ",
      );
    }
  }

  String dateTimeToSupabase(DateTime datetime) {
    return DateFormat(
      "yyyy-MM-dd",
    ).format(DateTime(datetime.year, datetime.month, datetime.day));
  }

  Future<List<LectureModel>> fetchLectures() async {
    if (AppModeManager.current == AppMode.lecturer) {
      return _fetchLecturesForLecturer();
    }
    return _fetchLecturesForStudent();
  }

  Future<List<LectureModel>> _fetchLecturesForStudent() async {
    if (Student.specialisation == null) {
      AppLogger.w("Specjalizacja studenta nie została ustawiona");
    }

    final List<String> selectedGroups = Student.selectedGroups ?? [];
    var query = Supabase.instance.client
        .from("v_lectures")
        .select()
        .eq("program_type", Student.studyMode?.programType ?? "S")
        .eq(
          "program_name",
          Student.specialisation ?? Student.degreeCourse ?? "",
        )
        .eq("year", Student.year ?? 0)
        .eq("degree_level", Student.degreeLevel ?? "");

    if (selectedGroups.isNotEmpty) {
      query = query.inFilter("group", selectedGroups);
    }

    final response = await query;
    final lectures = response
        .map((json) => LectureModel.fromJson(json))
        .toList();
    lectures.sort((a, b) => a.date.compareTo(b.date));
    return lectures;
  }

  Future<List<LectureModel>> _fetchLecturesForLecturer() async {
    if (Lecturer.id == null) {
      AppLogger.w("Brak ID prowadzącego");
      return [];
    }
    return fetchTeacherLectures(Lecturer.id!);
  }

  Future<List<String>> fetchGroups() async {
    if (kDebugEmptyGroups) return [];
    final response = await Supabase.instance.client
        .from("v_unique_groups")
        .select("group")
        .eq(
          "program_name",
          Student.specialisation ?? Student.degreeCourse ?? "",
        )
        .eq("program_type", Student.studyMode?.programType ?? "S")
        .eq("year", Student.year ?? 0)
        .eq("degree_level", Student.degreeLevel ?? "");

    return response.map((row) => row["group"] as String).toList()..sort();
  }

  Future<List<LecturerItem>> fetchTeachers() async {
    final response = await Supabase.instance.client
        .from("teachers")
        .select("id, fullName, title")
        .order("fullName", ascending: true);
    return response.map((json) => LecturerItem.fromJson(json)).toList();
  }

  Future<List<NewsModel>> fetchNews({int limit = 20}) async {
    if (kDebugNews) {
      return [
        NewsModel(
          id: 'debug-1',
          createdAt: DateTime.now(),
          title: 'Mock news — test obrazu',
          content:
              'To jest testowy news do weryfikacji ładowania zdjęć z ImgBB.',
          messageType: 'info',
          imageUrl: kDebugNewsImageUrl.isNotEmpty ? kDebugNewsImageUrl : null,
        ),
        NewsModel(
          id: 'debug-2',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          title: 'Mock news — bez zdjęcia',
          content: 'Ten news nie ma zdjęcia — sprawdza fallback.',
          messageType: 'warning',
        ),
      ];
    }
    AppLogger.d(
      "[BACKEND-SERVICE] fetchNews — wysyłam zapytanie (limit=$limit)",
    );
    try {
      final response = await Supabase.instance.client
          .from("news")
          .select()
          .order("created_at", ascending: false)
          .limit(limit);
      AppLogger.d(
        "[BACKEND-SERVICE] fetchNews — odpowiedź: ${response.length} wierszy",
      );
      if (response.isEmpty) return [];
      return response.map((json) {
        final id = json["id"].toString();
        return NewsModel(
          id: id,
          createdAt: DateTime.parse(json["created_at"]),
          title: json["title"] as String,
          content: json["content"] as String,
          messageType: json["message_type"] as String,
          imageUrl: json["image_url"] as String?,
        );
      }).toList();
    } catch (e, st) {
      AppLogger.e("[BACKEND-SERVICE] fetchNews — błąd zapytania", e, st);
      rethrow;
    }
  }

  Future<AnnouncementModel?> fetchAnnouncement() async {
    try {
      final response = await Supabase.instance.client
          .from("app_announcements")
          .select()
          .eq("active", true)
          .order("created_at", ascending: false)
          .limit(1);
      if (response.isEmpty) return null;
      return AnnouncementModel.fromJson(response.first);
    } catch (e) {
      AppLogger.w("[BACKEND-SERVICE] fetchAnnouncement — pominięto", e);
      return null;
    }
  }

  Future<void> clearCache() async {
    final db = DatabaseService.instance;
    await db.clearLectures();
    await db.clearNews();
    AppLogger.i("[BACKEND-SERVICE] Cache cleared");
  }

  /// Kombinacje studiów, dla których w bazie naprawdę są grupy — drzewko
  /// struktury złączone z planami po nazwie. Formularz onboardingu kaskaduje
  /// po tym, żeby nie dało się wybrać zestawu bez ani jednej grupy.
  Future<ProgramAvailability> fetchProgramAvailability() async {
    final structureRows = await Supabase.instance.client
        .from('v_academic_structure')
        .select();
    final programRows = await Supabase.instance.client
        .from('v_unique_groups')
        .select('program_name, year, program_type, degree_level');

    final availability = ProgramAvailability.from(
      structure: structureRows
          .map(
            (row) => StructureEntry(
              faculty: row['faculty_name'] as String,
              degreeCourse: row['degree_course_name'] as String,
              specialisation: row['specialisation_name'] as String?,
            ),
          )
          .toList(),
      programs: programRows
          .map(
            (row) => ProgramRow(
              programName: row['program_name'] as String,
              year: (row['year'] as num).toInt(),
              programType: row['program_type'] as String,
              degreeLevel: row['degree_level'] as String,
            ),
          )
          .toList(),
    );

    if (availability.unmatchedProgramNames.isNotEmpty) {
      // Plan, którego nazwa nie pasuje do żadnego węzła struktury, jest dla
      // studenta niewidoczny. Backend raportuje to samo na Discorda po każdym
      // przebiegu pipeline'u (structure_check) — tu zostaje ślad w logach.
      AppLogger.w(
        "[BACKEND-SERVICE] Plany bez węzła w strukturze: "
        "${availability.unmatchedProgramNames.join(', ')}",
      );
    }
    return availability;
  }

  Future<List<Map<String, dynamic>>> fetchAllTeachers() async {
    final response = await Supabase.instance.client
        .from('v_teachers_search')
        .select()
        .order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<LectureModel>> fetchTeacherLectures(String teacherId) async {
    final response = await Supabase.instance.client
        .from("v_teacher_lectures")
        .select()
        .eq("teacher_id", teacherId);

    final List<dynamic> data = response;
    final lectures = data.map((json) => LectureModel.fromJson(json)).toList();
    lectures.sort((a, b) => a.date.compareTo(b.date));
    return lectures;
  }
}
