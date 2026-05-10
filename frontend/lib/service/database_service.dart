// Lokalny cache SQLite — dwie tabele: lectures i news.
// Singleton otwierający bazę przy pierwszym dostępie przez getter [database].
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/api/models/news_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _db;

  DatabaseService._constructor();

  static const int dbVersion = 2;

  // Lectures
  static const String _lecturesTableName = "lectures";
  static const String _lecturesIdColumnName = "id";
  static const String _lecturesNameColumnName = "name";
  static const String _lecturesStartTimeColumnName = "start_time";
  static const String _lecturesEndTimeColumnName = "end_time";
  static const String _lecturesRoomColumnName = "room";
  static const String _lecturesBuildingColumnName = "building";
  static const String _lecturesLocationColumnName = "location";
  static const String _lecturesProfessorColumnName = "professor";
  static const String _lecturesGroupColumnName = "group_name";
  static const String _lecturesDurationColumnName = "duration";
  static const String _lecturesDateColumnName = "date";
  static const String _lecturesNotesColumnName = "notes";
  static const String _lecturesProgramNameColumnName = "program_name";
  static const String _lecturesYearColumnName = "year";
  static const String _lecturesDegreeLevelColumnName = "degree_level";

  // News
  static const String _newsTableName = "news";
  static const String _newsIdColumnName = "id";
  static const String _newsCreatedAtColumnName = "created_at";
  static const String _newsImageUrlColumnName = "image_url";
  static const String _newsContentColumnName = "content";
  static const String _newsMessageTypeColumnName = "messageType";
  static const String _newsTitleColumnName = "title";

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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_lecturesTableName ADD COLUMN $_lecturesProgramNameColumnName TEXT');
          await db.execute('ALTER TABLE $_lecturesTableName ADD COLUMN $_lecturesYearColumnName INTEGER');
          await db.execute('ALTER TABLE $_lecturesTableName ADD COLUMN $_lecturesDegreeLevelColumnName TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
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
          $_lecturesNotesColumnName TEXT,
          $_lecturesProgramNameColumnName TEXT,
          $_lecturesYearColumnName INTEGER,
          $_lecturesDegreeLevelColumnName TEXT
        );
        ''');
        await db.execute('''
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
    String? programName,
    int? year,
    String? degreeLevel,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      _lecturesIdColumnName: ?id,
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
      _lecturesProgramNameColumnName: programName,
      _lecturesYearColumnName: year,
      _lecturesDegreeLevelColumnName: degreeLevel,
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
    return data.map((row) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        row[_lecturesDateColumnName] as int,
      );
      return LectureModel(
        id: row[_lecturesIdColumnName].toString(),
        name: row[_lecturesNameColumnName] as String,
        startTime: row[_lecturesStartTimeColumnName] as String,
        endTime: row[_lecturesEndTimeColumnName] as String,
        room: row[_lecturesRoomColumnName] as String?,
        building: row[_lecturesBuildingColumnName] as String?,
        location: row[_lecturesLocationColumnName] as String?,
        professor: row[_lecturesProfessorColumnName] as String?,
        group: row[_lecturesGroupColumnName] as String,
        duration: row[_lecturesDurationColumnName] as String,
        date: date,
        notes: row[_lecturesNotesColumnName] as String?,
        programName: row[_lecturesProgramNameColumnName] as String?,
        year: row[_lecturesYearColumnName] as int?,
        degreeLevel: row[_lecturesDegreeLevelColumnName] as String?,
      );
    }).toList();
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
      _newsIdColumnName: ?id,
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
      _newsTableName,
      orderBy: '$_newsCreatedAtColumnName DESC',
      limit: limit,
    );
    return data.map((row) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        row[_newsCreatedAtColumnName] as int,
      );
      return NewsModel(
        id: row[_newsIdColumnName].toString(),
        title: row[_newsTitleColumnName] as String,
        createdAt: createdAt,
        imageUrl: row[_newsImageUrlColumnName] as String?,
        content: row[_newsContentColumnName] as String? ?? '',
        messageType: row[_newsMessageTypeColumnName] as String? ?? '',
      );
    }).toList();
  }
}
