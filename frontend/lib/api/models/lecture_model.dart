import 'package:intl/intl.dart';

class LectureModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String? room;
  final String? building;
  final String? location;
  final String? professor;
  final String group;
  final String duration;
  final DateTime date;
  final String? notes;

  LectureModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.group,
    required this.professor,
    required this.date,
    this.location,
    required this.duration,
    this.room,
    this.building,
    this.notes,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> teachersObject = json["teachersclasses"];
    String? professors;
    if (teachersObject.isEmpty) {
      professors = null;
    } else {
      professors = teachersObject
          .map((t) {
            final teacher = t["teachers"];
            if (teacher == null) return null;
            return "${teacher["title"] ?? ""} ${teacher["fullName"] ?? ""}"
                .trim();
          })
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .join(", ");
    }

    DateTime timeFrom = DateTime.parse(json["startTime"]);
    DateTime timeTo = DateTime.parse(json["endTime"]);
    int duration = timeTo.difference(timeFrom).inMinutes;
    String? location;
    String? building;
    String? notes = json["notes"];
    if (json["rooms"] == null) {
      location = null;
      building = null;
    } else {
      if (json["rooms"]["building"] == null) {
        location = null;
        building = null;
      } else {
        if (json["rooms"]["building"]["name"] == null) {
          location = null;
          building = null;
        } else {
          location =
              "${json["rooms"]["building"]["name"]} ${json["rooms"]["name"]}";
          building = json["rooms"]["building"]["name"];
        }
      }
    }

    return LectureModel(
      id: json["id"] as String,
      name: json["subject"] as String,
      startTime: DateFormat.Hm().format(timeFrom).toString(),
      endTime: DateFormat.Hm().format(timeTo).toString(),
      room: location,
      building: building,
      group: json["group"] as String,
      professor: professors,
      date: DateTime(
        timeFrom.year,
        timeFrom.month,
        timeFrom.day,
        timeFrom.hour,
        timeFrom.minute,
      ),
      duration: "$duration min",
      location: location,
      notes: notes,
    );
  }

  @override
  String toString() {
    return 'Lecture(id: $id, name: $name, startTime: $startTime, endTime: $endTime, room: $room, building: $building, location: $location, professor: $professor, group: $group, duration: $duration)';
  }
}
