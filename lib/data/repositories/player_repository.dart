import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/campaign.dart';
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

  Future<List<Campaign>> getCampaignsByPlayer(String playerId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT c.* FROM campaigns c
      JOIN campaign_players cp ON c.id = cp.campaign_id
      WHERE cp.player_id = ?
      ORDER BY c.name ASC
    ''',
      [playerId],
    );
    return results.map((m) => Campaign.fromMap(m)).toList();
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
    final results = await db.rawQuery(
      '''
      SELECT ch.* FROM characters ch
      JOIN campaign_characters cc ON ch.id = cc.character_id
      WHERE cc.campaign_id = ?
      ORDER BY ch.name ASC
    ''',
      [campaignId],
    );
    return results.map((m) => Character.fromMap(m)).toList();
  }

  Future<List<Character>> getCharactersByUser(String userId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT ch.* FROM characters ch
      JOIN players p ON ch.player_id = p.id
      WHERE p.user_id = ?
      ORDER BY ch.name ASC
    ''',
      [userId],
    );
    return results.map((m) => Character.fromMap(m)).toList();
  }

  Future<Character?> getActiveCharacterForPlayerInCampaign({
    required String playerId,
    required String campaignId,
  }) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT ch.* FROM characters ch
      JOIN campaign_characters cc ON ch.id = cc.character_id
      WHERE ch.player_id = ? AND cc.campaign_id = ? AND ch.status = ?
      LIMIT 1
    ''',
      [playerId, campaignId, CharacterStatus.active.value],
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
    // Remove all campaign links first, then the character itself
    await db.delete(
      'campaign_characters',
      where: 'character_id = ?',
      whereArgs: [id],
    );
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // CAMPAIGN-CHARACTER LINKS
  // ============================================

  Future<CampaignCharacter> addCharacterToCampaign({
    required String campaignId,
    required String characterId,
  }) async {
    final db = await _db.database;
    final link = CampaignCharacter(
      id: _uuid.v4(),
      campaignId: campaignId,
      characterId: characterId,
      joinedAt: DateTime.now(),
    );
    await db.insert('campaign_characters', link.toMap());
    return link;
  }

  Future<void> removeCharacterFromCampaign({
    required String campaignId,
    required String characterId,
  }) async {
    final db = await _db.database;
    await db.delete(
      'campaign_characters',
      where: 'campaign_id = ? AND character_id = ?',
      whereArgs: [campaignId, characterId],
    );
  }

  Future<bool> isCharacterInCampaign({
    required String campaignId,
    required String characterId,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'campaign_characters',
      where: 'campaign_id = ? AND character_id = ?',
      whereArgs: [campaignId, characterId],
    );
    return results.isNotEmpty;
  }

  Future<List<Campaign>> getCampaignsByCharacter(String characterId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT c.* FROM campaigns c
      JOIN campaign_characters cc ON c.id = cc.campaign_id
      WHERE cc.character_id = ?
      ORDER BY c.name ASC
    ''',
      [characterId],
    );
    return results.map((m) => Campaign.fromMap(m)).toList();
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
