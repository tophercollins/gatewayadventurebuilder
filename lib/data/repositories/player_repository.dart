import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/character.dart';
import '../models/player.dart';
import '../models/session.dart';

/// Repository for players, characters, and campaign-player links.
class PlayerRepository {
  PlayerRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  // ============================================
  // PLAYERS
  // ============================================

  Future<Player> createPlayer({
    required String userId,
    required String name,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final player = Player(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('players', player.toMap());
    return player;
  }

  Future<Player?> getPlayerById(String id) async {
    final db = await _db.database;
    final results = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Player.fromMap(results.first);
  }

  Future<List<Player>> getPlayersByUser(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'players',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Player.fromMap(m)).toList();
  }

  Future<List<Player>> getPlayersByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT p.* FROM players p
      JOIN campaign_players cp ON p.id = cp.player_id
      WHERE cp.campaign_id = ?
      ORDER BY p.name ASC
    ''',
      [campaignId],
    );
    return results.map((m) => Player.fromMap(m)).toList();
  }

  Future<void> updatePlayer(Player player) async {
    final db = await _db.database;
    await db.update(
      'players',
      player.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<void> deletePlayer(String id) async {
    final db = await _db.database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // CAMPAIGN-PLAYER LINKS
  // ============================================

  Future<CampaignPlayer> addPlayerToCampaign({
    required String campaignId,
    required String playerId,
  }) async {
    final db = await _db.database;
    final link = CampaignPlayer(
      id: _uuid.v4(),
      campaignId: campaignId,
      playerId: playerId,
      joinedAt: DateTime.now(),
    );
    await db.insert('campaign_players', link.toMap());
    return link;
  }

  Future<void> removePlayerFromCampaign({
    required String campaignId,
    required String playerId,
  }) async {
    final db = await _db.database;
    await db.delete(
      'campaign_players',
      where: 'campaign_id = ? AND player_id = ?',
      whereArgs: [campaignId, playerId],
    );
  }

  Future<bool> isPlayerInCampaign({
    required String campaignId,
    required String playerId,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'campaign_players',
      where: 'campaign_id = ? AND player_id = ?',
      whereArgs: [campaignId, playerId],
    );
    return results.isNotEmpty;
  }

  // ============================================
  // CHARACTERS
  // ============================================

  Future<Character> createCharacter({
    required String playerId,
    required String campaignId,
    required String name,
    String? characterClass,
    String? race,
    int? level,
    String? backstory,
    String? goals,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final character = Character(
      id: _uuid.v4(),
      playerId: playerId,
      campaignId: campaignId,
      name: name,
      characterClass: characterClass,
      race: race,
      level: level,
      backstory: backstory,
      goals: goals,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('characters', character.toMap());
    return character;
  }

  Future<Character?> getCharacterById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Character.fromMap(results.first);
  }

  Future<List<Character>> getCharactersByPlayer(String playerId) async {
    final db = await _db.database;
    final results = await db.query(
      'characters',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => Character.fromMap(m)).toList();
  }

  Future<List<Character>> getCharactersByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.query(
      'characters',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Character.fromMap(m)).toList();
  }

  Future<Character?> getActiveCharacterForPlayerInCampaign({
    required String playerId,
    required String campaignId,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'characters',
      where: 'player_id = ? AND campaign_id = ? AND status = ?',
      whereArgs: [playerId, campaignId, CharacterStatus.active.value],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Character.fromMap(results.first);
  }

  Future<void> updateCharacter(Character character) async {
    final db = await _db.database;
    await db.update(
      'characters',
      character.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<void> deleteCharacter(String id) async {
    final db = await _db.database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns sessions that a character attended, ordered by date descending.
  Future<List<Session>> getSessionsByCharacter(String characterId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT s.* FROM sessions s
      JOIN session_attendees sa ON s.id = sa.session_id
      WHERE sa.character_id = ?
      ORDER BY s.date DESC
    ''',
      [characterId],
    );
    return results.map((m) => Session.fromMap(m)).toList();
  }
}
