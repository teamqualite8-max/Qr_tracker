// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/part.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qr_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE parts (
            part_id TEXT PRIMARY KEY,
            status TEXT NOT NULL DEFAULT 'NOT_PROCESSED',
            post1_timestamp TEXT,
            post1_image_path TEXT,
            post2_timestamp TEXT,
            post2_image_path TEXT
          )
        ''');
      },
    );
  }

  // Insert or ignore (used during CSV import)
  Future<void> insertPartIfNotExists(Part part) async {
    final db = await database;
    await db.insert(
      'parts',
      part.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Bulk import parts from CSV
  Future<int> bulkInsertParts(List<String> partIds) async {
    final db = await database;
    int inserted = 0;

    final batch = db.batch();
    for (final id in partIds) {
      batch.insert(
        'parts',
        Part(partId: id).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    final results = await batch.commit(noResult: false);
    inserted = results.where((r) => r != null && r != -1).length;
    return inserted;
  }

  // Get single part by ID
  Future<Part?> getPartById(String partId) async {
    final db = await database;
    final maps = await db.query(
      'parts',
      where: 'part_id = ?',
      whereArgs: [partId],
    );
    if (maps.isEmpty) return null;
    return Part.fromMap(maps.first);
  }

  // Update part after Post 1
  Future<void> updatePost1(String partId, DateTime timestamp, String imagePath) async {
    final db = await database;
    await db.update(
      'parts',
      {
        'status': PartStatus.post1Done.label,
        'post1_timestamp': timestamp.toIso8601String(),
        'post1_image_path': imagePath,
      },
      where: 'part_id = ?',
      whereArgs: [partId],
    );
  }

  // Update part after Post 2
  Future<void> updatePost2(String partId, DateTime timestamp, String imagePath) async {
    final db = await database;
    await db.update(
      'parts',
      {
        'status': PartStatus.post2Done.label,
        'post2_timestamp': timestamp.toIso8601String(),
        'post2_image_path': imagePath,
      },
      where: 'part_id = ?',
      whereArgs: [partId],
    );
  }

  // Get all parts
  Future<List<Part>> getAllParts() async {
    final db = await database;
    final maps = await db.query('parts', orderBy: 'part_id ASC');
    return maps.map((m) => Part.fromMap(m)).toList();
  }

  // Dashboard stats
  Future<Map<String, int>> getStats() async {
    final db = await database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM parts'),
    ) ?? 0;

    final post1Done = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM parts WHERE status IN ('POST1_DONE', 'POST2_DONE')",
      ),
    ) ?? 0;

    final post2Done = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM parts WHERE status = 'POST2_DONE'",
      ),
    ) ?? 0;

    return {
      'total': total,
      'post1Done': post1Done,
      'post2Done': post2Done,
      'notProcessed': total - post1Done,
    };
  }

  // Check if a partId exists in the database
  Future<bool> partExists(String partId) async {
    final db = await database;
    final result = await db.query(
      'parts',
      where: 'part_id = ?',
      whereArgs: [partId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Delete all parts (reset)
  Future<void> clearAllParts() async {
    final db = await database;
    await db.delete('parts');
  }
}
