import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'schema.dart';

/// SQLite database helper for desktop platforms.
/// Uses sqflite_common_ffi for Windows/Mac/Linux support.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  /// Singleton instance.
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// Database version for migrations.
  static const int _version = 6;

  /// Database filename.
  static const String _dbName = 'ttrpg_tracker.db';

  /// Get database instance, initializing if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop
    sqfliteFfiInit();

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, 'ttrpg_tracker', _dbName);

    // Ensure directory exists
    final dbDir = Directory(dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  /// Create all tables on first launch.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Create all tables
    for (final sql in DatabaseSchema.createTableStatements) {
      batch.execute(sql);
    }

    // Create all indexes
    for (final sql in DatabaseSchema.createIndexStatements) {
      batch.execute(sql);
    }

    await batch.commit(noResult: true);
  }

  /// Handle database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE session_transcripts ADD COLUMN edited_text TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE session_summaries ADD COLUMN podcast_script TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE monsters (
          id TEXT PRIMARY KEY,
          world_id TEXT NOT NULL REFERENCES worlds(id),
          copied_from_id TEXT REFERENCES monsters(id),
          name TEXT NOT NULL,
          description TEXT,
          monster_type TEXT,
          notes TEXT,
          is_edited INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_monsters_world ON monsters(world_id)');
    }
    if (oldVersion < 5) {
      for (final table in [
        'worlds',
        'campaigns',
        'players',
        'characters',
        'npcs',
        'locations',
        'items',
      ]) {
        await db.execute('ALTER TABLE $table ADD COLUMN image_path TEXT');
      }
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE monsters ADD COLUMN image_path TEXT');
      await db.execute('''
        CREATE TABLE organisations (
          id TEXT PRIMARY KEY,
          world_id TEXT NOT NULL REFERENCES worlds(id),
          copied_from_id TEXT REFERENCES organisations(id),
          name TEXT NOT NULL,
          description TEXT,
          organisation_type TEXT,
          notes TEXT,
          is_edited INTEGER DEFAULT 0,
          image_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_organisations_world ON organisations(world_id)',
      );
    }
  }

  /// Called when database is opened.
  Future<void> _onOpen(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Close the database.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database file. Use with caution.
  Future<void> deleteDatabase() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDir.path, 'ttrpg_tracker', _dbName);
    final file = File(dbPath);
    if (await file.exists()) {
      await close();
      await file.delete();
    }
  }

  /// Inject a pre-configured database for testing.
  @visibleForTesting
  static void setTestDatabase(Database db) {
    _instance ??= DatabaseHelper._();
    _database = db;
  }

  /// Reset the singleton for test teardown.
  @visibleForTesting
  static void resetInstance() {
    _database = null;
    _instance = null;
  }
}
