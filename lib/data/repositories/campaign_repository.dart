import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Transaction;
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/world.dart';

/// Repository for campaigns and worlds.
class CampaignRepository {
  CampaignRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  // ============================================
  // WORLDS
  // ============================================

  Future<World> createWorld({
    required String userId,
    required String name,
    String? description,
    String? gameSystem,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final world = World(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      description: description,
      gameSystem: gameSystem,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('worlds', world.toMap());
    return world;
  }

  Future<World?> getWorldById(String id) async {
    final db = await _db.database;
    final results = await db.query('worlds', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return World.fromMap(results.first);
  }

  Future<List<World>> getWorldsByUser(String userId) async {
    final db = await _db.database;
    final results = await db.query(
      'worlds',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return results.map((m) => World.fromMap(m)).toList();
  }

  Future<void> updateWorld(World world) async {
    final db = await _db.database;
    await db.update(
      'worlds',
      world.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [world.id],
    );
  }

  Future<void> deleteWorld(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Get all campaigns in this world
      final campaigns = await txn.query(
        'campaigns',
        columns: ['id'],
        where: 'world_id = ?',
        whereArgs: [id],
      );

      // Delete all data for each campaign
      for (final row in campaigns) {
        final campaignId = row['id'] as String;
        await _deleteCampaignData(txn, campaignId);
      }

      // Delete campaigns themselves
      await txn.rawDelete(
        'DELETE FROM campaigns WHERE world_id = ?',
        [id],
      );

      // World-level entity children: npc_relationships, npc_quotes
      const npcSubquery = 'SELECT id FROM npcs WHERE world_id = ?';
      await txn.rawDelete(
        'DELETE FROM npc_relationships WHERE npc_id IN ($npcSubquery)',
        [id],
      );
      await txn.rawDelete(
        'DELETE FROM npc_quotes WHERE npc_id IN '
        '($npcSubquery)',
        [id],
      );

      // World-level entities
      for (final table in [
        'npcs',
        'locations',
        'items',
        'monsters',
        'organisations',
      ]) {
        await txn.rawDelete(
          'DELETE FROM $table WHERE world_id = ?',
          [id],
        );
      }

      // Finally, delete the world itself
      await txn.delete('worlds', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ============================================
  // CAMPAIGNS
  // ============================================

  /// Creates a campaign, auto-creating a world if needed.
  Future<Campaign> createCampaign({
    required String userId,
    required String name,
    String? worldId,
    String? description,
    String? gameSystem,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    // Create world if not provided
    String actualWorldId = worldId ?? '';
    if (worldId == null) {
      final world = await createWorld(
        userId: userId,
        name: name,
        gameSystem: gameSystem,
      );
      actualWorldId = world.id;
    }

    final campaign = Campaign(
      id: _uuid.v4(),
      worldId: actualWorldId,
      name: name,
      description: description,
      gameSystem: gameSystem,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('campaigns', campaign.toMap());
    return campaign;
  }

  Future<Campaign?> getCampaignById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'campaigns',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Campaign.fromMap(results.first);
  }

  Future<List<Campaign>> getCampaignsByWorld(String worldId) async {
    final db = await _db.database;
    final results = await db.query(
      'campaigns',
      where: 'world_id = ?',
      whereArgs: [worldId],
      orderBy: 'updated_at DESC',
    );
    return results.map((m) => Campaign.fromMap(m)).toList();
  }

  Future<List<Campaign>> getCampaignsByUser(String userId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT c.* FROM campaigns c
      JOIN worlds w ON c.world_id = w.id
      WHERE w.user_id = ?
      ORDER BY c.updated_at DESC
    ''',
      [userId],
    );
    return results.map((m) => Campaign.fromMap(m)).toList();
  }

  Future<void> updateCampaign(Campaign campaign) async {
    final db = await _db.database;
    await db.update(
      'campaigns',
      campaign.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [campaign.id],
    );
  }

  Future<void> deleteCampaign(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _deleteCampaignData(txn, id);
      await txn.delete('campaigns', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Deletes all data belonging to a campaign (but not the campaign row itself).
  /// Characters survive — only their campaign_characters links are removed.
  static Future<void> _deleteCampaignData(
    Transaction txn,
    String campaignId,
  ) async {
    const sessionSubquery =
        'SELECT id FROM sessions WHERE campaign_id = ?';
    const transcriptSubquery =
        'SELECT id FROM session_transcripts WHERE session_id IN ($sessionSubquery)';

    // Deepest children first: transcript_segments
    await txn.rawDelete(
      'DELETE FROM transcript_segments WHERE transcript_id IN ($transcriptSubquery)',
      [campaignId],
    );

    // Session-dependent tables
    for (final table in [
      'session_summaries',
      'scenes',
      'entity_appearances',
      'npc_quotes',
      'player_moments',
      'processing_queue',
      'session_attendees',
      'session_audio',
      'session_transcripts',
    ]) {
      await txn.rawDelete(
        'DELETE FROM $table WHERE session_id IN ($sessionSubquery)',
        [campaignId],
      );
    }

    // action_items references both session and campaign
    await txn.rawDelete(
      'DELETE FROM action_items WHERE campaign_id = ?',
      [campaignId],
    );

    // Direct campaign-dependent tables (characters survive, only links removed)
    for (final table in [
      'sessions',
      'campaign_players',
      'campaign_characters',
      'campaign_imports',
    ]) {
      await txn.rawDelete(
        'DELETE FROM $table WHERE campaign_id = ?',
        [campaignId],
      );
    }
  }

  /// Get campaign with its world.
  Future<({Campaign campaign, World world})?> getCampaignWithWorld(
    String campaignId,
  ) async {
    final campaign = await getCampaignById(campaignId);
    if (campaign == null) return null;
    final world = await getWorldById(campaign.worldId);
    if (world == null) return null;
    return (campaign: campaign, world: world);
  }
}
