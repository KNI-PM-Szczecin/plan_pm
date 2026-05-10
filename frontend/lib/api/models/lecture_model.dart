import 'package:intl/intl.dart';

/// Pojedyncze zajęcia pobierane z Supabase i cachowane w SQLite.
///
/// Model służy obu trybom — studenckiemu i wykładowcy. Pola [programName],
/// [year] i [degreeLevel] są wypełniane tylko w trybie wykładowcy (student
/// nie potrzebuje znać kierunku własnych zajęć). W trybie wykładowcy jeden
/// obiekt może reprezentować scalone zajęcia z kilku grup — wtedy [group]
/// zawiera kody rozdzielone przecinkiem (np. "L01,L02"), a [programName]
/// zawiera połączone nazwy kierunków.
///
/// Pełny cykl życia:
///   1. [BackendService.fetchLectures] pobiera dane z Supabase i buduje listę modeli
///   2. [CacheService.syncLectures] scala jednoczesne zajęcia (tryb wykładowcy),
///      a następnie zapisuje listę do SQLite
///   3. [DatabaseService.fetchLectures] odczytuje dane do wyświetlenia
///   4. [LecturesPage] i [TodayLectures] filtrują listę po dacie i przekazują
///      pola do widgetu [Lecture]
class LectureModel {
  final String id;

  /// Nazwa przedmiotu, np. "Programowanie obiektowe".
  final String name;

  /// Godzina rozpoczęcia w formacie "HH:mm", np. "09:45".
  final String startTime;

  /// Godzina zakończenia w formacie "HH:mm", np. "11:25".
  final String endTime;

  final String? room;
  final String? building;

  /// Połączona nazwa budynku i sali, np. "WChrobrego 176".
  /// Null gdy sala nie jest przypisana w bazie.
  final String? location;

  /// Imię i nazwisko prowadzącego z tytułem, np. "dr Jan Kowalski".
  /// W trybie studenta może zawierać kilku prowadzących rozdzielonych ", ".
  final String? professor;

  /// Kod grupy w surowym formacie z bazy, np. "L01" lub "L01,L02" po scaleniu.
  /// Widżet [Lecture] przetwarza to przez longToShort() do czytelnej postaci.
  final String group;

  /// Czas trwania w formacie "X min", np. "100 min".
  /// Widżet [Lecture] formatuje to do "1h 40min" przez formatDuration().
  final String duration;

  /// Data zajęć z uwzględnieniem godziny rozpoczęcia (lokalny czas).
  /// Używana do filtrowania zajęć po dniu i do obliczania paska postępu.
  final DateTime date;

  final String? notes;

  /// Nazwa kierunku studiów, np. "Informatyka". Tylko tryb wykładowcy.
  /// Po scaleniu zajęć z kilku kierunków zawiera nazwy rozdzielone ", ".
  final String? programName;

  /// Rok studiów grupy, np. 3. Tylko tryb wykładowcy.
  final int? year;

  /// Stopień studiów, np. "Engineering" lub "Masters". Tylko tryb wykładowcy.
  final String? degreeLevel;

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
    this.programName,
    this.year,
    this.degreeLevel,
  });

  /// Buduje model z JSON zwróconego przez Supabase.
  ///
  /// Kilka nieoczywistych decyzji:
  ///
  /// - [startTime] / [endTime] są przechowywane jako stringi "HH:mm" (nie DateTime),
  ///   bo widżet [Lecture] potrzebuje tekstowego formatu do wyświetlania i
  ///   do parsowania w _computeProgress(). DateFormat.Hm() konwertuje timestamp
  ///   do lokalnej strefy czasowej, więc godziny są zawsze w czasie użytkownika.
  ///
  /// - [date] jest konstruowany z komponentów timeFrom (rok/miesiąc/dzień/godzina),
  ///   a nie jako DateTime.parse() wprost — zapewnia to lokalny czas bez
  ///   przesunięcia UTC, co jest wymagane przez DateUtils.isSameDay() w widżetach.
  ///
  /// - [professor] łączy wszystkich prowadzących ze struktury teachersclasses
  ///   w jeden string. Puste tytuły są pomijane, żeby uniknąć zbędnych spacji.
  ///
  /// - [location] to "budynek sala", np. "WChrobrego 176". Null jeśli brakuje danych o sali w bazie
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
      room: roomName,
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
      programName: json["program_name"] as String?,
      year: json["year"] as int?,
      degreeLevel: json["degree_level"] as String?,
    );
  }

  @override
  String toString() {
    return 'Lecture(id: $id, name: $name, startTime: $startTime, endTime: $endTime, room: $room, building: $building, location: $location, professor: $professor, group: $group, duration: $duration)';
  }
}
