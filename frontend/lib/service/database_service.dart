import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _db;

  DatabaseService._constructor();

  final int dbVersion = 1;
  // Lectures
  final String _lecturesTableName = "lectures";
  final String _lecturesIdColumnName = "id";
  final String _lecturesNameColumnName = "name";
  final String _lecturesStartTimeColumnName = "start_time";
  final String _lecturesEndTimeColumnName = "end_time";
  final String _lecturesRoomColumnName = "room";
  final String _lecturesBuildingColumnName = "building";
  final String _lecturesLocationColumnName = "location";
  final String _lecturesProfessorColumnName = "professor";
  final String _lecturesGroupColumnName = "group_name";
  final String _lecturesDurationColumnName = "duration";
  final String _lecturesDateColumnName = "date";
  final String _lecturesNotesColumnName = "notes";
  // News
  final String _newsTableName = "news";
  final String _newsIdColumnName = "id";
  final String _newsCreatedAtColumnName = "created_at";
  final String _newsImageUrlColumnName = "image_url";
  final String _newsContentColumnName = "content";
  final String _newsMessageTypeColumnName = "messageType";
  final String _newsTitleColumnName = "title";

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "master_db.db");

    final database = await openDatabase(
      databasePath,
      version: dbVersion,
      onCreate: (db, version) {
        db.execute('''
        CREATE TABLE $_lecturesTableName (
          $_lecturesIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
          $_lecturesNameColumnName TEXT NOT NULL,
          $_lecturesStartTimeColumnName TEXT,
          $_lecturesEndTimeColumnName TEXT,
          $_lecturesRoomColumnName TEXT,
          $_lecturesBuildingColumnName TEXT,
          $_lecturesLocationColumnName TEXT,
          $_lecturesProfessorColumnName TEXT,
          $_lecturesGroupColumnName TEXT,
          $_lecturesDurationColumnName TEXT,
          $_lecturesDateColumnName INTEGER,
          $_lecturesNotesColumnName TEXT
        );
        ''');
        db.execute('''
        CREATE TABLE $_newsTableName(
          $_newsIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
          $_newsCreatedAtColumnName INTEGER NOT NULL,
          $_newsTitleColumnName TEXT,
          $_newsContentColumnName TEXT,
          $_newsMessageTypeColumnName TEXT,
          $_newsImageUrlColumnName TEXT
        );
        ''');
      },
    );
    return database;
  }

  Future<int> addLecture({
    int? id,
    required String name,
    required String startTime,
    required String endTime,
    String? room,
    String? building,
    String? location,
    String? professor,
    required String group,
    required String duration,
    required DateTime date,
    String? notes,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      if (id != null) _lecturesIdColumnName: id,
      _lecturesNameColumnName: name,
      _lecturesStartTimeColumnName: startTime,
      _lecturesEndTimeColumnName: endTime,
      _lecturesRoomColumnName: room,
      _lecturesBuildingColumnName: building,
      _lecturesLocationColumnName: location,
      _lecturesProfessorColumnName: professor,
      _lecturesGroupColumnName: group,
      _lecturesDurationColumnName: duration,
      _lecturesDateColumnName: date.toUtc().millisecondsSinceEpoch,
      _lecturesNotesColumnName: notes,
    };
    return await db.insert(
      _lecturesTableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> clearLectures() async {
    final db = await database;
    return await db.delete(_lecturesTableName);
  }

  Future<int> clearNews() async {
    final db = await database;
    return await db.delete(_newsTableName);
  }

  Future<List<LectureModel>> fetchLectures() async {
    final db = await database;
    final data = await db.query(_lecturesTableName);
    final lectures = data.map((lecture) {
      final date = DateTime.fromMillisecondsSinceEpoch(lecture["date"] as int);
      return LectureModel(
        location: lecture["location"] as String?,
        duration: lecture["duration"] as String,
        notes: lecture["notes"] as String?,
        id: lecture["id"].toString(),
        name: lecture["name"] as String,
        startTime: lecture["start_time"] as String,
        endTime: lecture["end_time"] as String,
        room: lecture["room"] as String?,
        building: lecture["building"] as String?,
        group: lecture["group_name"] as String,
        professor: lecture["professor"] as String?,
        date: date,
      );
    }).toList();
    return lectures;
  }

  Future<int> addNews({
    int? id,
    required DateTime createdAt,
    required String title,
    String? imageUrl,
    required String content,
    required String messageType,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      if (id != null) _newsIdColumnName: id,
      _newsTitleColumnName: title,
      _newsCreatedAtColumnName: createdAt.toUtc().millisecondsSinceEpoch,
      _newsImageUrlColumnName: imageUrl,
      _newsContentColumnName: content,
      _newsMessageTypeColumnName: messageType,
    };
    return await db.insert(
      _newsTableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NewsModel>> fetchNews({int limit = 5}) async {
    final db = await database;
    final data = await db.query(
      limit: limit,
      _newsTableName,
      orderBy: '$_newsCreatedAtColumnName DESC',
    );
    final newsList = data.map((row) {
      final createdAtMillis = row[_newsCreatedAtColumnName] as int;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
      return NewsModel(
        id: row[_newsIdColumnName].toString(),
        title: row[_newsTitleColumnName] as String,
        createdAt: createdAt,
        imageUrl: row[_newsImageUrlColumnName] as String? ?? '',
        content: row[_newsContentColumnName] as String? ?? '',
        messageType: row[_newsMessageTypeColumnName] as String? ?? '',
      );
    }).toList();
    return newsList;
  }
}
