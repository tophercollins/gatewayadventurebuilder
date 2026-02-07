import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

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
  static const int _version = 7;

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
    if (oldVersion < 7) {
      await _migrateCharactersToGlobal(db);
    }
  }

  /// Migrate characters from campaign-scoped to global (player-owned) entities.
  /// Creates campaign_characters join table and removes campaign_id from characters.
  static Future<void> _migrateCharactersToGlobal(Database db) async {
    const uuid = Uuid();

    // Disable foreign keys for schema changes
    await db.execute('PRAGMA foreign_keys = OFF');

    // Create the join table
    await db.execute('''
      CREATE TABLE campaign_characters (
        id TEXT PRIMARY KEY,
        campaign_id TEXT NOT NULL REFERENCES campaigns(id),
        character_id TEXT NOT NULL REFERENCES characters(id),
        joined_at TEXT NOT NULL,
        UNIQUE(campaign_id, character_id)
      )
    ''');

    // Populate join table from existing character → campaign links
    final characters = await db.query('characters');
    for (final row in characters) {
      final characterId = row['id'] as String;
      final campaignId = row['campaign_id'] as String?;
      if (campaignId != null && campaignId.isNotEmpty) {
        await db.insert('campaign_characters', {
          'id': uuid.v4(),
          'campaign_id': campaignId,
          'character_id': characterId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // Recreate characters table without campaign_id
    await db.execute('''
      CREATE TABLE characters_new (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL REFERENCES players(id),
        name TEXT NOT NULL,
        character_class TEXT,
        race TEXT,
        level INTEGER,
        backstory TEXT,
        goals TEXT,
        notes TEXT,
        status TEXT DEFAULT 'active',
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO characters_new (
        id, player_id, name, character_class, race, level,
        backstory, goals, notes, status, image_path, created_at, updated_at
      )
      SELECT
        id, player_id, name, character_class, race, level,
        backstory, goals, notes, status, image_path, created_at, updated_at
      FROM characters
    ''');

    await db.execute('DROP TABLE characters');
    await db.execute('ALTER TABLE characters_new RENAME TO characters');

    // Create indexes on the join table
    await db.execute(
      'CREATE INDEX idx_campaign_characters_campaign '
      'ON campaign_characters(campaign_id)',
    );
    await db.execute(
      'CREATE INDEX idx_campaign_characters_character '
      'ON campaign_characters(character_id)',
    );

    await db.execute('PRAGMA foreign_keys = ON');
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
