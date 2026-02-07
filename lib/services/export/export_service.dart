import 'dart:convert';

import 'package:intl/intl.dart';

import '../../data/models/action_item.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/item.dart';
import '../../data/models/location.dart';
import '../../data/models/monster.dart';
import '../../data/models/npc.dart';
import '../../data/models/organisation.dart';
import '../../data/models/scene.dart';
import '../../data/models/session.dart';
import '../../data/models/session_summary.dart';
import '../../data/models/session_transcript.dart';
import '../../data/repositories/action_item_repository.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/repositories/entity_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/summary_repository.dart';

/// Service for exporting session and campaign data in multiple formats.
///
/// Each method returns a [String] containing the formatted content.
/// The caller is responsible for writing the result to disk.
class ExportService {
  /// Exports a single session as Markdown.
  Future<String> exportSessionMarkdown({
    required String sessionId,
    required SessionRepository sessionRepo,
    required SummaryRepository summaryRepo,
    required ActionItemRepository actionItemRepo,
    required EntityRepository entityRepo,
    required CampaignRepository campaignRepo,
  }) async {
    final session = await sessionRepo.getSessionById(sessionId);
    if (session == null) return '# Session not found';

    final summary = await summaryRepo.getSummaryBySession(sessionId);
    final scenes = await summaryRepo.getScenesBySession(sessionId);
    final transcript = await sessionRepo.getLatestTranscript(sessionId);
    final actionItems = await actionItemRepo.getBySession(sessionId);

    final campaign = await campaignRepo.getCampaignById(session.campaignId);
    final entities = await _resolveSessionEntities(
      sessionId: sessionId,
      campaignId: session.campaignId,
      entityRepo: entityRepo,
      campaignRepo: campaignRepo,
    );

    return _buildMarkdown(
      session: session,
      campaignName: campaign?.name,
      summary: summary,
      scenes: scenes,
      transcript: transcript,
      npcs: entities.npcs,
      locations: entities.locations,
      items: entities.items,
      monsters: entities.monsters,
      organisations: entities.organisations,
      actionItems: actionItems,
    );
  }

  /// Exports a single session as JSON.
  Future<String> exportSessionJson({
    required String sessionId,
    required SessionRepository sessionRepo,
    required SummaryRepository summaryRepo,
    required ActionItemRepository actionItemRepo,
    required EntityRepository entityRepo,
    required CampaignRepository campaignRepo,
  }) async {
    final session = await sessionRepo.getSessionById(sessionId);
    if (session == null) return '{}';

    final summary = await summaryRepo.getSummaryBySession(sessionId);
    final scenes = await summaryRepo.getScenesBySession(sessionId);
    final transcript = await sessionRepo.getLatestTranscript(sessionId);
    final actionItems = await actionItemRepo.getBySession(sessionId);

    final entities = await _resolveSessionEntities(
      sessionId: sessionId,
      campaignId: session.campaignId,
      entityRepo: entityRepo,
      campaignRepo: campaignRepo,
    );

    final data = {
      'session': session.toMap(),
      'summary': summary != null
          ? {'overallSummary': summary.overallSummary}
          : null,
      'scenes': scenes
          .map(
            (s) => {
              'index': s.sceneIndex,
              'title': s.title,
              'summary': s.summary,
            },
          )
          .toList(),
      'transcript': transcript != null
          ? {'rawText': transcript.rawText, 'editedText': transcript.editedText}
          : null,
      'entities': {
        'npcs': entities.npcs.map(_npcToJson).toList(),
        'locations': entities.locations.map(_locationToJson).toList(),
        'items': entities.items.map(_itemToJson).toList(),
        'monsters': entities.monsters.map(_monsterToJson).toList(),
        'organisations': entities.organisations.map(_organisationToJson).toList(),
      },
      'actionItems': actionItems
          .map(
            (a) => {
              'title': a.title,
              'description': a.description,
              'status': a.status.value,
              'type': a.actionType,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports a full campaign with all sessions and world entities as JSON.
  Future<String> exportCampaignJson({
    required String campaignId,
    required CampaignRepository campaignRepo,
    required SessionRepository sessionRepo,
    required SummaryRepository summaryRepo,
    required EntityRepository entityRepo,
  }) async {
    final campaign = await campaignRepo.getCampaignById(campaignId);
    if (campaign == null) return '{}';

    final sessions = await sessionRepo.getSessionsByCampaign(campaignId);
    final campaignWithWorld = await campaignRepo.getCampaignWithWorld(
      campaignId,
    );
    final worldId = campaignWithWorld?.world.id;

    final sessionList = <Map<String, dynamic>>[];
    for (final session in sessions) {
      final summary = await summaryRepo.getSummaryBySession(session.id);
      final scenes = await summaryRepo.getScenesBySession(session.id);
      final transcript = await sessionRepo.getLatestTranscript(session.id);

      sessionList.add({
        'session': session.toMap(),
        'summary': summary?.overallSummary,
        'scenes': scenes
            .map((s) => {'title': s.title, 'summary': s.summary})
            .toList(),
        'transcript': transcript?.displayText,
      });
    }

    Map<String, dynamic> entitiesData = {};
    if (worldId != null) {
      final npcs = await entityRepo.getNpcsByWorld(worldId);
      final locations = await entityRepo.getLocationsByWorld(worldId);
      final items = await entityRepo.getItemsByWorld(worldId);
      final monsters = await entityRepo.getMonstersByWorld(worldId);
      final organisations = await entityRepo.getOrganisationsByWorld(worldId);
      entitiesData = {
        'npcs': npcs.map(_npcToJson).toList(),
        'locations': locations.map(_locationToJson).toList(),
        'items': items.map(_itemToJson).toList(),
        'monsters': monsters.map(_monsterToJson).toList(),
        'organisations': organisations.map(_organisationToJson).toList(),
      };
    }

    final data = {
      'campaign': campaign.toMap(),
      'world': campaignWithWorld?.world.toMap(),
      'sessions': sessionList,
      'entities': entitiesData,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports world entities of a given type as CSV.
  ///
  /// Supported [entityType] values: `'npc'`, `'location'`, `'item'`, `'monster'`, `'organisation'`.
  Future<String> exportEntitiesCsv({
    required String worldId,
    required EntityRepository entityRepo,
    required String entityType,
  }) async {
    switch (entityType) {
      case 'npc':
        return _exportNpcsCsv(worldId, entityRepo);
      case 'location':
        return _exportLocationsCsv(worldId, entityRepo);
      case 'item':
        return _exportItemsCsv(worldId, entityRepo);
      case 'monster':
        return _exportMonstersCsv(worldId, entityRepo);
      case 'organisation':
        return _exportOrganisationsCsv(worldId, entityRepo);
      default:
        return '';
    }
  }

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------

  String _buildMarkdown({
    required Session session,
    String? campaignName,
    SessionSummary? summary,
    required List<Scene> scenes,
    SessionTranscript? transcript,
    required List<Npc> npcs,
    required List<Location> locations,
    required List<Item> items,
    required List<Monster> monsters,
    required List<Organisation> organisations,
    required List<ActionItem> actionItems,
  }) {
    final buf = StringBuffer();
    final dateStr = DateFormat('MMMM d, y').format(session.date);
    final title = session.title ?? 'Session ${session.sessionNumber ?? '?'}';

    buf.writeln('# $title');
    buf.writeln('**Date:** $dateStr');
    if (campaignName != null) buf.writeln('**Campaign:** $campaignName');
    buf.writeln();

    if (summary?.overallSummary != null) {
      buf.writeln('## Summary');
      buf.writeln(summary!.overallSummary!);
      buf.writeln();
    }

    if (scenes.isNotEmpty) {
      buf.writeln('## Scenes');
      for (final scene in scenes) {
        final sceneTitle = scene.title ?? 'Scene ${scene.sceneIndex + 1}';
        buf.writeln('### $sceneTitle');
        if (scene.summary != null) buf.writeln(scene.summary!);
        buf.writeln();
      }
    }

    if (npcs.isNotEmpty ||
        locations.isNotEmpty ||
        items.isNotEmpty ||
        monsters.isNotEmpty ||
        organisations.isNotEmpty) {
      buf.writeln('## Entities Mentioned');
      if (npcs.isNotEmpty) {
        buf.writeln('- **NPCs:** ${npcs.map((n) => n.name).join(', ')}');
      }
      if (locations.isNotEmpty) {
        buf.writeln(
          '- **Locations:** ${locations.map((l) => l.name).join(', ')}',
        );
      }
      if (items.isNotEmpty) {
        buf.writeln('- **Items:** ${items.map((i) => i.name).join(', ')}');
      }
      if (monsters.isNotEmpty) {
        buf.writeln(
          '- **Monsters:** ${monsters.map((m) => m.name).join(', ')}',
        );
      }
      if (organisations.isNotEmpty) {
        buf.writeln(
          '- **Organisations:** ${organisations.map((o) => o.name).join(', ')}',
        );
      }
      buf.writeln();
    }

    if (actionItems.isNotEmpty) {
      buf.writeln('## Action Items');
      for (final item in actionItems) {
        final check = item.status == ActionItemStatus.resolved ? 'x' : ' ';
        buf.writeln('- [$check] ${item.title}');
      }
      buf.writeln();
    }

    if (transcript != null) {
      buf.writeln('## Transcript');
      buf.writeln(transcript.displayText);
      buf.writeln();
    }

    return buf.toString();
  }

  Future<_SessionEntities> _resolveSessionEntities({
    required String sessionId,
    required String campaignId,
    required EntityRepository entityRepo,
    required CampaignRepository campaignRepo,
  }) async {
    final campaignWithWorld = await campaignRepo.getCampaignWithWorld(
      campaignId,
    );
    if (campaignWithWorld == null) {
      return const _SessionEntities(
        npcs: [],
        locations: [],
        items: [],
        monsters: [],
        organisations: [],
      );
    }

    final worldId = campaignWithWorld.world.id;
    final appearances = await entityRepo.getAppearancesBySession(sessionId);

    final npcIds = appearances
        .where((a) => a.entityType == EntityType.npc)
        .map((a) => a.entityId)
        .toSet();
    final locationIds = appearances
        .where((a) => a.entityType == EntityType.location)
        .map((a) => a.entityId)
        .toSet();
    final itemIds = appearances
        .where((a) => a.entityType == EntityType.item)
        .map((a) => a.entityId)
        .toSet();
    final monsterIds = appearances
        .where((a) => a.entityType == EntityType.monster)
        .map((a) => a.entityId)
        .toSet();
    final organisationIds = appearances
        .where((a) => a.entityType == EntityType.organisation)
        .map((a) => a.entityId)
        .toSet();

    final allNpcs = await entityRepo.getNpcsByWorld(worldId);
    final allLocations = await entityRepo.getLocationsByWorld(worldId);
    final allItems = await entityRepo.getItemsByWorld(worldId);
    final allMonsters = await entityRepo.getMonstersByWorld(worldId);
    final allOrganisations = await entityRepo.getOrganisationsByWorld(worldId);

    return _SessionEntities(
      npcs: allNpcs.where((n) => npcIds.contains(n.id)).toList(),
      locations: allLocations.where((l) => locationIds.contains(l.id)).toList(),
      items: allItems.where((i) => itemIds.contains(i.id)).toList(),
      monsters: allMonsters.where((m) => monsterIds.contains(m.id)).toList(),
      organisations: allOrganisations
          .where((o) => organisationIds.contains(o.id))
          .toList(),
    );
  }

  Map<String, dynamic> _npcToJson(Npc npc) => {
    'name': npc.name,
    'description': npc.description,
    'role': npc.role,
    'status': npc.status.value,
    'notes': npc.notes,
  };

  Map<String, dynamic> _locationToJson(Location location) => {
    'name': location.name,
    'description': location.description,
    'type': location.locationType,
    'notes': location.notes,
  };

  Map<String, dynamic> _itemToJson(Item item) => {
    'name': item.name,
    'description': item.description,
    'type': item.itemType,
    'properties': item.properties,
    'notes': item.notes,
  };

  Map<String, dynamic> _monsterToJson(Monster monster) => {
    'name': monster.name,
    'description': monster.description,
    'type': monster.monsterType,
    'notes': monster.notes,
  };

  Map<String, dynamic> _organisationToJson(Organisation org) => {
    'name': org.name,
    'description': org.description,
    'type': org.organisationType,
    'notes': org.notes,
  };

  Future<String> _exportNpcsCsv(
    String worldId,
    EntityRepository entityRepo,
  ) async {
    final npcs = await entityRepo.getNpcsByWorld(worldId);
    final buf = StringBuffer();
    buf.writeln('Name,Description,Role,Status,Notes');
    for (final npc in npcs) {
      buf.writeln(
        '${_csvEscape(npc.name)},${_csvEscape(npc.description)},'
        '${_csvEscape(npc.role)},${_csvEscape(npc.status.value)},'
        '${_csvEscape(npc.notes)}',
      );
    }
    return buf.toString();
  }

  Future<String> _exportLocationsCsv(
    String worldId,
    EntityRepository entityRepo,
  ) async {
    final locations = await entityRepo.getLocationsByWorld(worldId);
    final buf = StringBuffer();
    buf.writeln('Name,Description,Type,Notes');
    for (final loc in locations) {
      buf.writeln(
        '${_csvEscape(loc.name)},${_csvEscape(loc.description)},'
        '${_csvEscape(loc.locationType)},${_csvEscape(loc.notes)}',
      );
    }
    return buf.toString();
  }

  Future<String> _exportItemsCsv(
    String worldId,
    EntityRepository entityRepo,
  ) async {
    final items = await entityRepo.getItemsByWorld(worldId);
    final buf = StringBuffer();
    buf.writeln('Name,Description,Type,Properties,Notes');
    for (final item in items) {
      buf.writeln(
        '${_csvEscape(item.name)},${_csvEscape(item.description)},'
        '${_csvEscape(item.itemType)},${_csvEscape(item.properties)},'
        '${_csvEscape(item.notes)}',
      );
    }
    return buf.toString();
  }

  Future<String> _exportMonstersCsv(
    String worldId,
    EntityRepository entityRepo,
  ) async {
    final monsters = await entityRepo.getMonstersByWorld(worldId);
    final buf = StringBuffer();
    buf.writeln('Name,Description,Type,Notes');
    for (final monster in monsters) {
      buf.writeln(
        '${_csvEscape(monster.name)},${_csvEscape(monster.description)},'
        '${_csvEscape(monster.monsterType)},${_csvEscape(monster.notes)}',
      );
    }
    return buf.toString();
  }

  Future<String> _exportOrganisationsCsv(
    String worldId,
    EntityRepository entityRepo,
  ) async {
    final organisations = await entityRepo.getOrganisationsByWorld(worldId);
    final buf = StringBuffer();
    buf.writeln('Name,Description,Type,Notes');
    for (final org in organisations) {
      buf.writeln(
        '${_csvEscape(org.name)},${_csvEscape(org.description)},'
        '${_csvEscape(org.organisationType)},${_csvEscape(org.notes)}',
      );
    }
    return buf.toString();
  }

  String _csvEscape(String? value) {
    if (value == null) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _SessionEntities {
  const _SessionEntities({
    required this.npcs,
    required this.locations,
    required this.items,
    required this.monsters,
    required this.organisations,
  });
  final List<Npc> npcs;
  final List<Location> locations;
  final List<Item> items;
  final List<Monster> monsters;
  final List<Organisation> organisations;
}
