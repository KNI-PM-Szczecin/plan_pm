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
  /// - [location] to "budynek sala", np. "WChrobrego 176". Null jeśli którykolwiek
  ///   z poziomów zagnieżdżenia (rooms → building → name) jest null w bazie.
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

    final programs = json["programs"];
    final String? programName = programs?["name"] as String?;
    final int? year = programs?["year"] as int?;
    final String? degreeLevel = programs?["degreeLevel"] as String?;

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
      programName: programName,
      year: year,
      degreeLevel: degreeLevel,
    );
  }

  @override
  String toString() {
    return 'Lecture(id: $id, name: $name, startTime: $startTime, endTime: $endTime, room: $room, building: $building, location: $location, professor: $professor, group: $group, duration: $duration)';
  }
}
