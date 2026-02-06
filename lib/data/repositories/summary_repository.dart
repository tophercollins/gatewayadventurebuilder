import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/scene.dart';
import '../models/session_summary.dart';

/// Repository for session summaries and scenes.
class SummaryRepository {
  SummaryRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  // ============================================
  // SESSION SUMMARIES
  // ============================================

  Future<SessionSummary> createSummary({
    required String sessionId,
    String? transcriptId,
    String? overallSummary,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final summary = SessionSummary(
      id: _uuid.v4(),
      sessionId: sessionId,
      transcriptId: transcriptId,
      overallSummary: overallSummary,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('session_summaries', summary.toMap());
    return summary;
  }

  Future<SessionSummary?> getSummaryBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'session_summaries',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SessionSummary.fromMap(results.first);
  }

  Future<SessionSummary?> getSummaryById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'session_summaries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SessionSummary.fromMap(results.first);
  }

  Future<void> updateSummary(
    SessionSummary summary, {
    bool markEdited = false,
  }) async {
    final db = await _db.database;
    final updated = summary.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : summary.isEdited,
    );
    await db.update(
      'session_summaries',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [summary.id],
    );
  }

  Future<void> deleteSummary(String id) async {
    final db = await _db.database;
    await db.delete('session_summaries', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // SCENES
  // ============================================

  Future<Scene> createScene({
    required String sessionId,
    required int sceneIndex,
    String? title,
    String? summary,
    int? startTimeMs,
    int? endTimeMs,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final scene = Scene(
      id: _uuid.v4(),
      sessionId: sessionId,
      sceneIndex: sceneIndex,
      title: title,
      summary: summary,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('scenes', scene.toMap());
    return scene;
  }

  Future<List<Scene>> createScenes(List<Scene> scenes) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final scene in scenes) {
      batch.insert('scenes', scene.toMap());
    }
    await batch.commit(noResult: true);
    return scenes;
  }

  Future<List<Scene>> getScenesBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'scenes',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'scene_index ASC',
    );
    return results.map((m) => Scene.fromMap(m)).toList();
  }

  Future<Scene?> getSceneById(String id) async {
    final db = await _db.database;
    final results = await db.query('scenes', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Scene.fromMap(results.first);
  }

  Future<void> updateScene(Scene scene, {bool markEdited = false}) async {
    final db = await _db.database;
    final updated = scene.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : scene.isEdited,
    );
    await db.update('scenes', updated.toMap(), where: 'id = ?', whereArgs: [scene.id]);
  }

  Future<void> deleteScene(String id) async {
    final db = await _db.database;
    await db.delete('scenes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteScenesBySession(String sessionId) async {
    final db = await _db.database;
    await db.delete('scenes', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}
