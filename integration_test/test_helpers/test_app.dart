import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_tracker/config/routes.dart';
import 'package:ttrpg_tracker/data/database/database_helper.dart';
import 'package:ttrpg_tracker/data/database/schema.dart';
import 'package:ttrpg_tracker/ui/theme/app_theme.dart';

/// Creates an in-memory SQLite database with the full app schema.
Future<Database> createTestDatabase() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final sql in DatabaseSchema.createTableStatements) {
          batch.execute(sql);
        }
        for (final sql in DatabaseSchema.createIndexStatements) {
          batch.execute(sql);
        }
        await batch.commit(noResult: true);
      },
    ),
  );
  await db.execute('PRAGMA foreign_keys = ON');
  return db;
}

/// Builds a test app with a fresh router starting at [initialLocation].
Widget buildTestApp({required String initialLocation}) {
  final router = createAppRouter(initialLocation: initialLocation);

  return ProviderScope(
    child: MaterialApp.router(
      title: 'History Check Test',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Sets up the test environment: mocks SharedPreferences, creates
/// an in-memory DB, and injects it into [DatabaseHelper].
/// Returns the [Database] for teardown.
Future<Database> setUpTestEnvironment() async {
  SharedPreferences.setMockInitialValues({});
  final db = await createTestDatabase();
  DatabaseHelper.setTestDatabase(db);
  return db;
}

/// Creates a [ProviderContainer] with optional overrides.
/// Use for programmatic (non-widget) tests that drive the pipeline directly.
ProviderContainer buildTestContainer({
  List<Override> overrides = const [],
}) {
  return ProviderContainer(overrides: overrides);
}

/// Tears down the test environment: closes the DB and resets
/// the [DatabaseHelper] singleton.
Future<void> tearDownTestEnvironment(Database db) async {
  await db.close();
  DatabaseHelper.resetInstance();
}
