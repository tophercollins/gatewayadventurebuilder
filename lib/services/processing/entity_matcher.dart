import '../../data/models/entity_appearance.dart';
import '../../data/models/item.dart';
import '../../data/models/location.dart';
import '../../data/models/monster.dart';
import '../../data/models/npc.dart';
import '../../data/repositories/entity_repository.dart';
import 'llm_response_models.dart';

/// Result of matching an extracted entity to existing entities.
class EntityMatchResult<T> {
  const EntityMatchResult({
    required this.entity,
    required this.isNew,
    required this.wasUpdated,
  });

  /// The entity (new or existing).
  final T entity;

  /// True if this is a newly created entity.
  final bool isNew;

  /// True if an existing entity was updated with new info.
  final bool wasUpdated;
}

/// Handles matching extracted entities against existing world entities.
/// Creates new entities or links to existing ones.
class EntityMatcher {
  EntityMatcher(this._entityRepo);

  final EntityRepository _entityRepo;

  /// Match NPCs extracted from LLM to existing world NPCs.
  /// Creates new NPCs or returns existing matches.
  Future<List<EntityMatchResult<Npc>>> matchNpcs({
    required String worldId,
    required List<NpcData> extractedNpcs,
  }) async {
    final existingNpcs = await _entityRepo.getNpcsByWorld(worldId);
    final results = <EntityMatchResult<Npc>>[];

    for (final extracted in extractedNpcs) {
      final match = _findNpcMatch(extracted.name, existingNpcs);

      if (match != null) {
        // Existing NPC found - update if not edited and has new info
        var wasUpdated = false;
        if (!match.isEdited) {
          final updatedNpc = _mergeNpcData(match, extracted);
          if (updatedNpc != match) {
            await _entityRepo.updateNpc(updatedNpc);
            wasUpdated = true;
            results.add(
              EntityMatchResult(
                entity: updatedNpc,
                isNew: false,
                wasUpdated: true,
              ),
            );
            continue;
          }
        }
        results.add(
          EntityMatchResult(
            entity: match,
            isNew: false,
            wasUpdated: wasUpdated,
          ),
        );
      } else {
        // New NPC - create it
        final newNpc = await _entityRepo.createNpc(
          worldId: worldId,
          name: extracted.name,
          description: extracted.description,
          role: extracted.role,
        );
        results.add(
          EntityMatchResult(entity: newNpc, isNew: true, wasUpdated: false),
        );
      }
    }

    return results;
  }

  /// Match locations extracted from LLM to existing world locations.
  Future<List<EntityMatchResult<Location>>> matchLocations({
    required String worldId,
    required List<LocationData> extractedLocations,
  }) async {
    final existingLocations = await _entityRepo.getLocationsByWorld(worldId);
    final results = <EntityMatchResult<Location>>[];

    for (final extracted in extractedLocations) {
      final match = _findLocationMatch(extracted.name, existingLocations);

      if (match != null) {
        var wasUpdated = false;
        if (!match.isEdited) {
          final updatedLoc = _mergeLocationData(match, extracted);
          if (updatedLoc != match) {
            await _entityRepo.updateLocation(updatedLoc);
            wasUpdated = true;
            results.add(
              EntityMatchResult(
                entity: updatedLoc,
                isNew: false,
                wasUpdated: true,
              ),
            );
            continue;
          }
        }
        results.add(
          EntityMatchResult(
            entity: match,
            isNew: false,
            wasUpdated: wasUpdated,
          ),
        );
      } else {
        final newLocation = await _entityRepo.createLocation(
          worldId: worldId,
          name: extracted.name,
          description: extracted.description,
          locationType: extracted.locationType,
        );
        results.add(
          EntityMatchResult(
            entity: newLocation,
            isNew: true,
            wasUpdated: false,
          ),
        );
      }
    }

    return results;
  }

  /// Match items extracted from LLM to existing world items.
  Future<List<EntityMatchResult<Item>>> matchItems({
    required String worldId,
    required List<ItemData> extractedItems,
  }) async {
    final existingItems = await _entityRepo.getItemsByWorld(worldId);
    final results = <EntityMatchResult<Item>>[];

    for (final extracted in extractedItems) {
      final match = _findItemMatch(extracted.name, existingItems);

      if (match != null) {
        var wasUpdated = false;
        if (!match.isEdited) {
          final updatedItem = _mergeItemData(match, extracted);
          if (updatedItem != match) {
            await _entityRepo.updateItem(updatedItem);
            wasUpdated = true;
            results.add(
              EntityMatchResult(
                entity: updatedItem,
                isNew: false,
                wasUpdated: true,
              ),
            );
            continue;
          }
        }
        results.add(
          EntityMatchResult(
            entity: match,
            isNew: false,
            wasUpdated: wasUpdated,
          ),
        );
      } else {
        final newItem = await _entityRepo.createItem(
          worldId: worldId,
          name: extracted.name,
          description: extracted.description,
          itemType: extracted.itemType,
          properties: extracted.properties,
        );
        results.add(
          EntityMatchResult(entity: newItem, isNew: true, wasUpdated: false),
        );
      }
    }

    return results;
  }

  /// Match monsters extracted from LLM to existing world monsters.
  Future<List<EntityMatchResult<Monster>>> matchMonsters({
    required String worldId,
    required List<MonsterData> extractedMonsters,
  }) async {
    final existingMonsters = await _entityRepo.getMonstersByWorld(worldId);
    final results = <EntityMatchResult<Monster>>[];

    for (final extracted in extractedMonsters) {
      final match = _findMonsterMatch(extracted.name, existingMonsters);

      if (match != null) {
        var wasUpdated = false;
        if (!match.isEdited) {
          final updatedMonster = _mergeMonsterData(match, extracted);
          if (updatedMonster != match) {
            await _entityRepo.updateMonster(updatedMonster);
            wasUpdated = true;
            results.add(
              EntityMatchResult(
                entity: updatedMonster,
                isNew: false,
                wasUpdated: true,
              ),
            );
            continue;
          }
        }
        results.add(
          EntityMatchResult(
            entity: match,
            isNew: false,
            wasUpdated: wasUpdated,
          ),
        );
      } else {
        final newMonster = await _entityRepo.createMonster(
          worldId: worldId,
          name: extracted.name,
          description: extracted.description,
          monsterType: extracted.monsterType,
        );
        results.add(
          EntityMatchResult(
            entity: newMonster,
            isNew: true,
            wasUpdated: false,
          ),
        );
      }
    }

    return results;
  }

  /// Create entity appearances for the session.
  Future<void> createAppearances({
    required String sessionId,
    required List<EntityMatchResult<Npc>> npcs,
    required List<EntityMatchResult<Location>> locations,
    required List<EntityMatchResult<Item>> items,
    required List<EntityMatchResult<Monster>> monsters,
    required List<NpcData> npcData,
    required List<LocationData> locationData,
    required List<ItemData> itemData,
    required List<MonsterData> monsterData,
  }) async {
    // Create NPC appearances
    for (var i = 0; i < npcs.length; i++) {
      final result = npcs[i];
      final data = i < npcData.length ? npcData[i] : null;
      await _entityRepo.createAppearance(
        sessionId: sessionId,
        entityType: EntityType.npc,
        entityId: result.entity.id,
        context: data?.context,
        firstAppearance: result.isNew,
        timestampMs: data?.timestampMs,
      );
    }

    // Create location appearances
    for (var i = 0; i < locations.length; i++) {
      final result = locations[i];
      final data = i < locationData.length ? locationData[i] : null;
      await _entityRepo.createAppearance(
        sessionId: sessionId,
        entityType: EntityType.location,
        entityId: result.entity.id,
        context: data?.context,
        firstAppearance: result.isNew,
        timestampMs: data?.timestampMs,
      );
    }

    // Create item appearances
    for (var i = 0; i < items.length; i++) {
      final result = items[i];
      final data = i < itemData.length ? itemData[i] : null;
      await _entityRepo.createAppearance(
        sessionId: sessionId,
        entityType: EntityType.item,
        entityId: result.entity.id,
        context: data?.context,
        firstAppearance: result.isNew,
        timestampMs: data?.timestampMs,
      );
    }

    // Create monster appearances
    for (var i = 0; i < monsters.length; i++) {
      final result = monsters[i];
      final data = i < monsterData.length ? monsterData[i] : null;
      await _entityRepo.createAppearance(
        sessionId: sessionId,
        entityType: EntityType.monster,
        entityId: result.entity.id,
        context: data?.context,
        firstAppearance: result.isNew,
        timestampMs: data?.timestampMs,
      );
    }
  }

  // Private helper methods

  Npc? _findNpcMatch(String name, List<Npc> existing) {
    final normalizedName = _normalizeName(name);
    for (final npc in existing) {
      if (_normalizeName(npc.name) == normalizedName) {
        return npc;
      }
    }
    return null;
  }

  Location? _findLocationMatch(String name, List<Location> existing) {
    final normalizedName = _normalizeName(name);
    for (final loc in existing) {
      if (_normalizeName(loc.name) == normalizedName) {
        return loc;
      }
    }
    return null;
  }

  Item? _findItemMatch(String name, List<Item> existing) {
    final normalizedName = _normalizeName(name);
    for (final item in existing) {
      if (_normalizeName(item.name) == normalizedName) {
        return item;
      }
    }
    return null;
  }

  String _normalizeName(String name) {
    return name.toLowerCase().trim();
  }

  Npc _mergeNpcData(Npc existing, NpcData extracted) {
    // Only merge if existing fields are empty
    return existing.copyWith(
      description: existing.description ?? extracted.description,
      role: existing.role ?? extracted.role,
    );
  }

  Location _mergeLocationData(Location existing, LocationData extracted) {
    return existing.copyWith(
      description: existing.description ?? extracted.description,
      locationType: existing.locationType ?? extracted.locationType,
    );
  }

  Item _mergeItemData(Item existing, ItemData extracted) {
    return existing.copyWith(
      description: existing.description ?? extracted.description,
      itemType: existing.itemType ?? extracted.itemType,
      properties: existing.properties ?? extracted.properties,
    );
  }

  Monster? _findMonsterMatch(String name, List<Monster> existing) {
    final normalizedName = _normalizeName(name);
    for (final monster in existing) {
      if (_normalizeName(monster.name) == normalizedName) {
        return monster;
      }
    }
    return null;
  }

  Monster _mergeMonsterData(Monster existing, MonsterData extracted) {
    return existing.copyWith(
      description: existing.description ?? extracted.description,
      monsterType: existing.monsterType ?? extracted.monsterType,
    );
  }
}
