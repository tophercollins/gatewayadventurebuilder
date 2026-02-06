import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/character.dart';
import '../data/models/entity_appearance.dart';
import '../data/models/item.dart';
import '../data/models/location.dart';
import '../data/models/npc.dart';
import '../data/models/npc_quote.dart';
import '../data/models/npc_relationship.dart';
import '../data/models/session.dart';
import 'repository_providers.dart';

/// Data class for an NPC with its appearance count.
class NpcWithCount {
  const NpcWithCount({required this.npc, required this.appearanceCount});
  final Npc npc;
  final int appearanceCount;
}

/// Data class for a location with its appearance count.
class LocationWithCount {
  const LocationWithCount({
    required this.location,
    required this.appearanceCount,
  });
  final Location location;
  final int appearanceCount;
}

/// Data class for an item with its appearance count.
class ItemWithCount {
  const ItemWithCount({required this.item, required this.appearanceCount});
  final Item item;
  final int appearanceCount;
}

/// Provider for all NPCs in a world with appearance counts.
final worldNpcsProvider = FutureProvider.autoDispose
    .family<List<NpcWithCount>, String>((ref, worldId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);

  final npcs = await entityRepo.getNpcsByWorld(worldId);
  final result = <NpcWithCount>[];

  for (final npc in npcs) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.npc,
      entityId: npc.id,
    );
    result.add(NpcWithCount(npc: npc, appearanceCount: count));
  }

  return result;
});

/// Provider for all locations in a world with appearance counts.
final worldLocationsProvider = FutureProvider.autoDispose
    .family<List<LocationWithCount>, String>((ref, worldId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);

  final locations = await entityRepo.getLocationsByWorld(worldId);
  final result = <LocationWithCount>[];

  for (final location in locations) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.location,
      entityId: location.id,
    );
    result.add(LocationWithCount(location: location, appearanceCount: count));
  }

  return result;
});

/// Provider for all items in a world with appearance counts.
final worldItemsProvider = FutureProvider.autoDispose
    .family<List<ItemWithCount>, String>((ref, worldId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);

  final items = await entityRepo.getItemsByWorld(worldId);
  final result = <ItemWithCount>[];

  for (final item in items) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.item,
      entityId: item.id,
    );
    result.add(ItemWithCount(item: item, appearanceCount: count));
  }

  return result;
});

/// Provider for entity appearances for a specific entity.
final entityAppearancesProvider = FutureProvider.autoDispose
    .family<List<EntityAppearance>, ({EntityType type, String entityId})>(
        (ref, params) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getAppearancesByEntity(
    entityType: params.type,
    entityId: params.entityId,
  );
});

/// Provider for NPC relationships.
final npcRelationshipsProvider = FutureProvider.autoDispose
    .family<List<NpcRelationship>, String>((ref, npcId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getNpcRelationships(npcId);
});

/// Provider for NPC quotes.
final npcQuotesProvider = FutureProvider.autoDispose
    .family<List<NpcQuote>, String>((ref, npcId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getNpcQuotes(npcId);
});

/// Provider for a single NPC by ID.
final npcByIdProvider =
    FutureProvider.autoDispose.family<Npc?, String>((ref, npcId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getNpcById(npcId);
});

/// Provider for a single location by ID.
final locationByIdProvider =
    FutureProvider.autoDispose.family<Location?, String>((ref, locationId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getLocationById(locationId);
});

/// Provider for a single item by ID.
final itemByIdProvider =
    FutureProvider.autoDispose.family<Item?, String>((ref, itemId) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  return await entityRepo.getItemById(itemId);
});

/// Provider for sessions where an entity appeared.
final entitySessionsProvider = FutureProvider.autoDispose
    .family<List<Session>, ({EntityType type, String entityId})>(
        (ref, params) async {
  final entityRepo = ref.watch(entityRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);

  final appearances = await entityRepo.getAppearancesByEntity(
    entityType: params.type,
    entityId: params.entityId,
  );

  final sessionIds = appearances.map((a) => a.sessionId).toSet();
  final sessions = <Session>[];

  for (final sessionId in sessionIds) {
    final session = await sessionRepo.getSessionById(sessionId);
    if (session != null) {
      sessions.add(session);
    }
  }

  sessions.sort((a, b) => b.date.compareTo(a.date));
  return sessions;
});

/// Provider to get character info for NPC relationships.
final characterByIdProvider =
    FutureProvider.autoDispose.family<Character?, String>((ref, charId) async {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return await playerRepo.getCharacterById(charId);
});

/// Aggregated world data for the world database screen.
class WorldDatabaseData {
  const WorldDatabaseData({
    required this.npcs,
    required this.locations,
    required this.items,
  });

  final List<NpcWithCount> npcs;
  final List<LocationWithCount> locations;
  final List<ItemWithCount> items;

  int get totalEntities => npcs.length + locations.length + items.length;
}

/// Provider for all world database data.
final worldDatabaseProvider = FutureProvider.autoDispose
    .family<WorldDatabaseData?, String>((ref, campaignId) async {
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  final entityRepo = ref.watch(entityRepositoryProvider);

  final campaignWithWorld = await campaignRepo.getCampaignWithWorld(campaignId);
  if (campaignWithWorld == null) return null;

  final worldId = campaignWithWorld.world.id;

  // Fetch all entities in parallel
  final npcs = await entityRepo.getNpcsByWorld(worldId);
  final locations = await entityRepo.getLocationsByWorld(worldId);
  final items = await entityRepo.getItemsByWorld(worldId);

  // Get counts for each
  final npcsWithCounts = <NpcWithCount>[];
  for (final npc in npcs) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.npc,
      entityId: npc.id,
    );
    npcsWithCounts.add(NpcWithCount(npc: npc, appearanceCount: count));
  }

  final locationsWithCounts = <LocationWithCount>[];
  for (final location in locations) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.location,
      entityId: location.id,
    );
    locationsWithCounts.add(
      LocationWithCount(location: location, appearanceCount: count),
    );
  }

  final itemsWithCounts = <ItemWithCount>[];
  for (final item in items) {
    final count = await entityRepo.countAppearances(
      entityType: EntityType.item,
      entityId: item.id,
    );
    itemsWithCounts.add(ItemWithCount(item: item, appearanceCount: count));
  }

  return WorldDatabaseData(
    npcs: npcsWithCounts,
    locations: locationsWithCounts,
    items: itemsWithCounts,
  );
});
