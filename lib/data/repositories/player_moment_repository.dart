import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/player_moment.dart';

/// Repository for player moments and highlights.
class PlayerMomentRepository {
  PlayerMomentRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  Future<PlayerMoment> create({
    required String sessionId,
    required String playerId,
    String? characterId,
    String? momentType,
    required String description,
    String? quoteText,
    int? timestampMs,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final moment = PlayerMoment(
      id: _uuid.v4(),
      sessionId: sessionId,
      playerId: playerId,
      characterId: characterId,
      momentType: momentType,
      description: description,
      quoteText: quoteText,
      timestampMs: timestampMs,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('player_moments', moment.toMap());
    return moment;
  }

  Future<PlayerMoment?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'player_moments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return PlayerMoment.fromMap(results.first);
  }

  Future<List<PlayerMoment>> getBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'player_moments',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp_ms ASC, created_at ASC',
    );
    return results.map((m) => PlayerMoment.fromMap(m)).toList();
  }

  Future<List<PlayerMoment>> getByPlayer(String playerId) async {
    final db = await _db.database;
    final results = await db.query(
      'player_moments',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => PlayerMoment.fromMap(m)).toList();
  }

  Future<List<PlayerMoment>> getBySessionAndPlayer({
    required String sessionId,
    required String playerId,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'player_moments',
      where: 'session_id = ? AND player_id = ?',
      whereArgs: [sessionId, playerId],
      orderBy: 'timestamp_ms ASC, created_at ASC',
    );
    return results.map((m) => PlayerMoment.fromMap(m)).toList();
  }

  Future<void> update(PlayerMoment moment, {bool markEdited = false}) async {
    final db = await _db.database;
    final updated = moment.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : moment.isEdited,
    );
    await db.update(
      'player_moments',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [moment.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('player_moments', where: 'id = ?', whereArgs: [id]);
  }
}
