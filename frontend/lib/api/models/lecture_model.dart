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
    DateTime timeFrom = DateTime.parse(json["start_time"]);
    DateTime timeTo = DateTime.parse(json["end_time"]);
    int duration = timeTo.difference(timeFrom).inMinutes;

    String? roomName = json["room_name"] as String?;
    String? buildingName = json["building_name"] as String?;
    String? location;

    if (buildingName != null && roomName != null) {
      location = "$buildingName $roomName";
    } else if (roomName != null) {
      location = roomName;
    }

    return LectureModel(
      id: json["id"].toString(),
      name: json["subject"] as String,
      startTime: DateFormat.Hm().format(timeFrom).toString(),
      endTime: DateFormat.Hm().format(timeTo).toString(),
      room: location,
      building: buildingName,
      group: json["group"] as String,
      
      professor: json["professors"] as String?, 
      
      date: DateTime(
        timeFrom.year,
        timeFrom.month,
        timeFrom.day,
        timeFrom.hour,
        timeFrom.minute,
      ),
      duration: "$duration min",
      location: location,
      notes: json["notes"] as String?,
    );
  }

  @override
  String toString() {
    return 'Lecture(id: $id, name: $name, startTime: $startTime, endTime: $endTime, room: $room, building: $building, location: $location, professor: $professor, group: $group, duration: $duration)';
  }
}
