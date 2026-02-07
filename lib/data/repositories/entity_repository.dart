import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/entity_appearance.dart';
import '../models/item.dart';
import '../models/location.dart';
import '../models/monster.dart';
import '../models/npc.dart';
import '../models/npc_quote.dart';
import '../models/npc_relationship.dart';

/// Repository for NPCs, locations, items, and entity appearances.
class EntityRepository {
  EntityRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  // ============================================
  // NPCS
  // ============================================

  Future<Npc> createNpc({
    required String worldId,
    required String name,
    String? description,
    String? role,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final npc = Npc(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      role: role,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('npcs', npc.toMap());
    return npc;
  }

  Future<Npc?> getNpcById(String id) async {
    final db = await _db.database;
    final results = await db.query('npcs', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Npc.fromMap(results.first);
  }

  Future<List<Npc>> getNpcsByWorld(String worldId) async {
    final db = await _db.database;
    final results = await db.query(
      'npcs',
      where: 'world_id = ?',
      whereArgs: [worldId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Npc.fromMap(m)).toList();
  }

  Future<Npc?> findNpcByName(String worldId, String name) async {
    final db = await _db.database;
    final results = await db.query(
      'npcs',
      where: 'world_id = ? AND name = ?',
      whereArgs: [worldId, name],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Npc.fromMap(results.first);
  }

  Future<void> updateNpc(Npc npc, {bool markEdited = false}) async {
    final db = await _db.database;
    final updated = npc.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : npc.isEdited,
    );
    await db.update(
      'npcs',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [npc.id],
    );
  }

  Future<void> deleteNpc(String id) async {
    final db = await _db.database;
    await db.delete('npcs', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // LOCATIONS
  // ============================================

  Future<Location> createLocation({
    required String worldId,
    required String name,
    String? description,
    String? locationType,
    String? parentLocationId,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final location = Location(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      locationType: locationType,
      parentLocationId: parentLocationId,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('locations', location.toMap());
    return location;
  }

  Future<Location?> getLocationById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Location.fromMap(results.first);
  }

  Future<List<Location>> getLocationsByWorld(String worldId) async {
    final db = await _db.database;
    final results = await db.query(
      'locations',
      where: 'world_id = ?',
      whereArgs: [worldId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Location.fromMap(m)).toList();
  }

  Future<void> updateLocation(
    Location location, {
    bool markEdited = false,
  }) async {
    final db = await _db.database;
    final updated = location.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : location.isEdited,
    );
    await db.update(
      'locations',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<void> deleteLocation(String id) async {
    final db = await _db.database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // ITEMS
  // ============================================

  Future<Item> createItem({
    required String worldId,
    required String name,
    String? description,
    String? itemType,
    String? properties,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final item = Item(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      itemType: itemType,
      properties: properties,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('items', item.toMap());
    return item;
  }

  Future<Item?> getItemById(String id) async {
    final db = await _db.database;
    final results = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Item.fromMap(results.first);
  }

  Future<List<Item>> getItemsByWorld(String worldId) async {
    final db = await _db.database;
    final results = await db.query(
      'items',
      where: 'world_id = ?',
      whereArgs: [worldId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Item.fromMap(m)).toList();
  }

  Future<void> updateItem(Item item, {bool markEdited = false}) async {
    final db = await _db.database;
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : item.isEdited,
    );
    await db.update(
      'items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await _db.database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // MONSTERS
  // ============================================

  Future<Monster> createMonster({
    required String worldId,
    required String name,
    String? description,
    String? monsterType,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final monster = Monster(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      monsterType: monsterType,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('monsters', monster.toMap());
    return monster;
  }

  Future<Monster?> getMonsterById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'monsters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Monster.fromMap(results.first);
  }

  Future<List<Monster>> getMonstersByWorld(String worldId) async {
    final db = await _db.database;
    final results = await db.query(
      'monsters',
      where: 'world_id = ?',
      whereArgs: [worldId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Monster.fromMap(m)).toList();
  }

  Future<Monster?> findMonsterByName(String worldId, String name) async {
    final db = await _db.database;
    final results = await db.query(
      'monsters',
      where: 'world_id = ? AND name = ?',
      whereArgs: [worldId, name],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Monster.fromMap(results.first);
  }

  Future<void> updateMonster(
    Monster monster, {
    bool markEdited = false,
  }) async {
    final db = await _db.database;
    final updated = monster.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : monster.isEdited,
    );
    await db.update(
      'monsters',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [monster.id],
    );
  }

  Future<void> deleteMonster(String id) async {
    final db = await _db.database;
    await db.delete('monsters', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // ENTITY APPEARANCES
  // ============================================

  Future<EntityAppearance> createAppearance({
    required String sessionId,
    required EntityType entityType,
    required String entityId,
    String? context,
    bool firstAppearance = false,
    int? timestampMs,
  }) async {
    final db = await _db.database;
    final appearance = EntityAppearance(
      id: _uuid.v4(),
      sessionId: sessionId,
      entityType: entityType,
      entityId: entityId,
      context: context,
      firstAppearance: firstAppearance,
      timestampMs: timestampMs,
      createdAt: DateTime.now(),
    );
    await db.insert('entity_appearances', appearance.toMap());
    return appearance;
  }

  Future<List<EntityAppearance>> getAppearancesBySession(
    String sessionId,
  ) async {
    final db = await _db.database;
    final results = await db.query(
      'entity_appearances',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return results.map((m) => EntityAppearance.fromMap(m)).toList();
  }

  Future<List<EntityAppearance>> getAppearancesByEntity({
    required EntityType entityType,
    required String entityId,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'entity_appearances',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType.value, entityId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => EntityAppearance.fromMap(m)).toList();
  }

  Future<void> deleteAppearance(String id) async {
    final db = await _db.database;
    await db.delete('entity_appearances', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countAppearances({
    required EntityType entityType,
    required String entityId,
  }) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM entity_appearances WHERE entity_type = ? AND entity_id = ?',
      [entityType.value, entityId],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ============================================
  // NPC RELATIONSHIPS
  // ============================================

  Future<NpcRelationship> createNpcRelationship({
    required String npcId,
    required String characterId,
    String? relationship,
    RelationshipSentiment sentiment = RelationshipSentiment.neutral,
  }) async {
    final db = await _db.database;
    final npcRelationship = NpcRelationship(
      id: _uuid.v4(),
      npcId: npcId,
      characterId: characterId,
      relationship: relationship,
      sentiment: sentiment,
      updatedAt: DateTime.now(),
    );
    await db.insert('npc_relationships', npcRelationship.toMap());
    return npcRelationship;
  }

  Future<List<NpcRelationship>> getNpcRelationships(String npcId) async {
    final db = await _db.database;
    final results = await db.query(
      'npc_relationships',
      where: 'npc_id = ?',
      whereArgs: [npcId],
    );
    return results.map((m) => NpcRelationship.fromMap(m)).toList();
  }

  Future<void> updateNpcRelationship(NpcRelationship relationship) async {
    final db = await _db.database;
    final updated = relationship.copyWith(updatedAt: DateTime.now());
    await db.update(
      'npc_relationships',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [relationship.id],
    );
  }

  Future<void> deleteNpcRelationship(String id) async {
    final db = await _db.database;
    await db.delete('npc_relationships', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // NPC QUOTES
  // ============================================

  Future<NpcQuote> createNpcQuote({
    required String npcId,
    required String sessionId,
    required String quoteText,
    String? context,
    int? timestampMs,
  }) async {
    final db = await _db.database;
    final quote = NpcQuote(
      id: _uuid.v4(),
      npcId: npcId,
      sessionId: sessionId,
      quoteText: quoteText,
      context: context,
      timestampMs: timestampMs,
      createdAt: DateTime.now(),
    );
    await db.insert('npc_quotes', quote.toMap());
    return quote;
  }

  Future<List<NpcQuote>> getNpcQuotes(String npcId) async {
    final db = await _db.database;
    final results = await db.query(
      'npc_quotes',
      where: 'npc_id = ?',
      whereArgs: [npcId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => NpcQuote.fromMap(m)).toList();
  }

  Future<void> deleteNpcQuote(String id) async {
    final db = await _db.database;
    await db.delete('npc_quotes', where: 'id = ?', whereArgs: [id]);
  }
}
