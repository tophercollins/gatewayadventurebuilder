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
    await db.delete('worlds', where: 'id = ?', whereArgs: [id]);
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
    await db.delete('campaigns', where: 'id = ?', whereArgs: [id]);
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
