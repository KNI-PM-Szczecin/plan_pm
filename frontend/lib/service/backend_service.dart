import 'package:intl/intl.dart';
// import 'dart:developer' as developer;
import 'package:plan_pm/api/models/announcement_model.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/models/lecturer.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:plan_pm/global/utils/logger.dart';

class BackendService {
  static final BackendService _backendService = BackendService._internal();

  void messToText(List<Map<String, dynamic>> response) {
    for (final value in response) {
      AppLogger.d(
        "${value["group"]}|${DateFormat.EEEE().format(DateTime.parse(value["startTime"]))}|${value["startTime"]} - ${value["endTime"]}, Subject: ${value["subject"]}, ",
      );
    }
  }

  String dateTimeToSupabase(DateTime datetime) {
    return DateFormat(
      "yyyy-MM-dd",
    ).format(DateTime(datetime.year, datetime.month, datetime.day));
  }

  factory BackendService() {
    return _backendService;
  }

  BackendService._internal();

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
        .from("classes")
        .select('''
        id,
        group,
        subject,
        startTime,
        endTime,
        programs!inner(name, programType, year, degreeLevel),
        teachersclasses(teachers(fullName, title)),
        rooms:room(
          name,
          building:building(name)
        )
      ''')
        .eq("programs.programType", Student.studyMode?.programType ?? "S")
        .eq(
          "programs.name",
          Student.specialisation ?? Student.degreeCourse ?? "",
        )
        .eq("programs.year", Student.year ?? 0)
        .eq("programs.degreeLevel", Student.degreeLevel ?? "");

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
    final teacherClasses = await Supabase.instance.client
        .from("teachersclasses")
        .select("classes")
        .eq("teachers", Lecturer.id!);

    final classIds = teacherClasses.map((r) => r["classes"] as String).toList();

    if (classIds.isEmpty) return [];

    final response = await Supabase.instance.client
        .from("classes")
        .select('''
        id,
        group,
        subject,
        startTime,
        endTime,
        programs(name, programType, year, degreeLevel),
        teachersclasses(teachers(fullName, title)),
        rooms:room(
          name,
          building:building(name)
        )
      ''')
        .inFilter("id", classIds);

    final lectures = response
        .map((json) => LectureModel.fromJson(json))
        .toList();
    lectures.sort((a, b) => a.date.compareTo(b.date));
    return lectures;
  }

  Future<List<String>> fetchGroups() async {
    final response = await Supabase.instance.client
        .from("classes")
        .select("group, programs!inner(name, programType, year, degreeLevel)")
        .eq(
          "programs.name",
          Student.specialisation ?? Student.degreeCourse ?? "",
        )
        .eq("programs.programType", Student.studyMode?.programType ?? "S")
        .eq("programs.year", Student.year ?? 0)
        .eq("programs.degreeLevel", Student.degreeLevel ?? "");

    final Set<String> uniqueGroups = {};
    for (final row in response) {
      uniqueGroups.add(row["group"] as String);
    }
    List<String> data = uniqueGroups.toList()..sort();
    return data;
  }

  Future<List<LecturerItem>> fetchTeachers() async {
    final response = await Supabase.instance.client
        .from("teachers")
        .select("id, fullName, title")
        .order("fullName", ascending: true);
    return response.map((json) => LecturerItem.fromJson(json)).toList();
  }

  Future<List<NewsModel>> fetchNews({int limit = 20}) async {
    AppLogger.d("[BACKEND-SERVICE] fetchNews — wysyłam zapytanie (limit=$limit)");
    try {
      final response = await Supabase.instance.client
          .from("news")
          .select()
          .limit(limit);
      AppLogger.d("[BACKEND-SERVICE] fetchNews — odpowiedź: ${response.length} wierszy");
      if (response.isEmpty) return [];
      return response.map((json) {
        return NewsModel(
          id: json["id"] as String,
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

  Future<Map<String, Map<String, List<String>>>> fetchStructure() async {
    // select f.name as faculty, d.name as degree_course, s.name as specialisation from faculties f join degree_courses d on f.id = d.faculty_id left join specialisations s on d.id = s.degree_course_id;
    final response = await Supabase.instance.client.from('faculties').select('''
          name,
          degree_courses!inner(
            name,
            specialisations!left(
              name
            )
          )
        ''');

    if (response.isNotEmpty) {
      final data = response;
      final Map<String, Map<String, List<String>>> facultiesMap = {
        for (var faculty in data)
          faculty["name"] as String: {
            for (var degreeCourse in faculty["degree_courses"])
              degreeCourse["name"] as String: [
                for (var specialisation in degreeCourse["specialisations"])
                  specialisation["name"] as String,
              ],
          },
      };
      // developer.log(facultiesMap.toString());
      return facultiesMap;
    }

    return {};
  }
}
