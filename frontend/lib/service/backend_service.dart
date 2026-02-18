import 'package:intl/intl.dart';
// import 'dart:developer' as developer;
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:plan_pm/global/student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendService {
  static final BackendService _backendService = BackendService._internal();

  void messToText(List<Map<String, dynamic>> response) {
    response.forEach((value) {
      print(
        "${value["group"]}|${DateFormat.EEEE().format(DateTime.parse(value["startTime"]))}|${value["startTime"]} - ${value["endTime"]}, Subject: ${value["subject"]}, ",
      );
    });
  }

  String DateTimeToSupabase(DateTime datetime) {
    return DateFormat(
      "yyyy-MM-dd",
    ).format(DateTime(datetime.year, datetime.month, datetime.day));
  }

  factory BackendService() {
    return _backendService;
  }

  BackendService._internal();

  Future<List<LectureModel>> fetchLectures() async {
    if (Student.specialisation == null) {
      print("Specjalizacja studenta nie została ustawiona");
    }
    final List<String> selectedGroups = Student.selectedGroups ?? [];

    // final today = filterDate;
    // final tomorrow = filterDate.add(Duration(days: 1));

    var query = Supabase.instance.client
        .from("classes")
        .select('''
        id,
        group,
        subject,
        startTime,
        endTime,
        programs!inner(name, programType, year),
        teachersclasses(teachers(fullName, title)),
        rooms:room(
          name,
          building:building(name)
        )
      ''')
        // .gte('startTime', DateTimeToSupabase(today))
        // .lt('startTime', DateTimeToSupabase(tomorrow))
        .eq("programs.programType", Student.term?[0] ?? "S")
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

    final data = response;

    // messToText(data);
    // developer.log(data.toString());

    // print(data);
    final lectures = data.map((json) => LectureModel.fromJson(json)).toList();
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
        .eq("programs.programType", Student.term?[0] ?? "S")
        .eq("programs.year", Student.year ?? 0)
        .eq("programs.degreeLevel", Student.degreeLevel ?? "");

    final Set<String> uniqueGroups = {};
    for (final row in response) {
      uniqueGroups.add(row["group"] as String);
    }
    List<String> data = uniqueGroups.toList()..sort();
    return data;
  }

  Future<List<NewsModel>> fetchNews({int limit = 20}) async {
    final response = await Supabase.instance.client
        .from("news")
        .select()
        .limit(limit);
    final data = response;
    if (data.isNotEmpty) {
      final news = data.map((json) {
        final id = json["id"] as String;
        final url = Supabase.instance.client.storage
            .from("Files")
            .getPublicUrl("News/$id.png");

        return NewsModel(
          id: json["id"] as String,
          createdAt: DateTime.parse(json["created_at"]),
          title: json["title"] as String,
          content: json["content"] as String,
          messageType: json["message_type"] as String,
          imageUrl: url,
        );
      }).toList();
      return news;
    }
    return [];
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
