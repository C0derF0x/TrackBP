import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/measurement.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const String _databaseName = 'bp_tracker.db';
  static const int _databaseVersion = 1;

  static const String _measurementsTable = 'measurements';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE $_measurementsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER,
        arm TEXT NOT NULL,
        measured_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_measurements_user_date
      ON $_measurementsTable (user_id, measured_at)
    ''');
  }

  Future<void> insertMeasurement(
    Measurement measurement,
  ) async {
    final db = await database;

    await db.insert(
      _measurementsTable,
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Updates an existing measurement using its ID.
  Future<int> updateMeasurement(
    Measurement measurement,
  ) async {
    final db = await database;

    return db.update(
      _measurementsTable,
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<List<Measurement>> getMeasurements(
    String userId,
  ) async {
    final db = await database;

    final maps = await db.query(
      _measurementsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measured_at DESC',
    );

    return maps.map(Measurement.fromMap).toList();
  }

  Future<Measurement?> getLatestMeasurement(
    String userId,
  ) async {
    final db = await database;

    final maps = await db.query(
      _measurementsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measured_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Measurement.fromMap(maps.first);
  }

  Future<int> deleteMeasurement(String id) async {
    final db = await database;

    return db.delete(
      _measurementsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes every measurement belonging to a particular user.
  Future<int> deleteAllMeasurements(String userId) async {
    final db = await database;

    return db.delete(
      _measurementsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}