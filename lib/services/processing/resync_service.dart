import 'dart:convert';

import '../../data/models/action_item.dart';
import '../../data/models/item.dart';
import '../../data/models/location.dart';
import '../../data/models/npc.dart';
import '../../data/models/scene.dart';
import '../../data/models/session_summary.dart';
import '../../data/repositories/action_item_repository.dart';
import '../../data/repositories/entity_repository.dart';
import '../../data/repositories/summary_repository.dart';
import 'llm_service.dart';
import 'prompts/resync_prompt.dart';

/// Result of a resync operation.
class ResyncResult {
  const ResyncResult.success({
    this.summaryUpdated = false,
    this.scenesUpdated = 0,
    this.entitiesUpdated = 0,
    this.actionItemsUpdated = 0,
  })  : error = null,
        isSuccess = true;

  const ResyncResult.failure(this.error)
      : isSuccess = false,
        summaryUpdated = false,
        scenesUpdated = 0,
        entitiesUpdated = 0,
        actionItemsUpdated = 0;

  final bool isSuccess;
  final String? error;
  final bool summaryUpdated;
  final int scenesUpdated;
  final int entitiesUpdated;
  final int actionItemsUpdated;

  int get totalUpdates =>
      (summaryUpdated ? 1 : 0) +
      scenesUpdated +
      entitiesUpdated +
      actionItemsUpdated;
}

/// Collected session content for resync.
class SessionContent {
  const SessionContent({
    this.summary,
    this.scenes = const [],
    this.npcs = const [],
    this.locations = const [],
    this.items = const [],
    this.actionItems = const [],
  });

  final SessionSummary? summary;
  final List<Scene> scenes;
  final List<Npc> npcs;
  final List<Location> locations;
  final List<Item> items;
  final List<ActionItem> actionItems;

  List<Scene> get editedScenes => scenes.where((s) => s.isEdited).toList();
  List<Scene> get uneditedScenes => scenes.where((s) => !s.isEdited).toList();

  List<Npc> get editedNpcs => npcs.where((n) => n.isEdited).toList();
  List<Location> get editedLocations =>
      locations.where((l) => l.isEdited).toList();
  List<Item> get editedItems => items.where((i) => i.isEdited).toList();

  List<ActionItem> get editedActionItems =>
      actionItems.where((a) => a.isEdited).toList();
  List<ActionItem> get uneditedActionItems =>
      actionItems.where((a) => !a.isEdited).toList();
}

/// Service for resyncing edited content across a session.
class ResyncService {
  ResyncService({
    required this.llmService,
    required this.summaryRepo,
    required this.entityRepo,
    required this.actionItemRepo,
  });

  final LLMService llmService;
  final SummaryRepository summaryRepo;
  final EntityRepository entityRepo;
  final ActionItemRepository actionItemRepo;

  /// Resync a session's content after edits.
  Future<ResyncResult> resyncSession({
    required String sessionId,
    required String worldId,
  }) async {
    // 1. Collect all content for the session
    final content = await _collectSessionContent(sessionId, worldId);

    // 2. Check if there's anything edited
    final hasEdits = (content.summary?.isEdited ?? false) ||
        content.editedScenes.isNotEmpty ||
        content.editedNpcs.isNotEmpty ||
        content.editedLocations.isNotEmpty ||
        content.editedItems.isNotEmpty ||
        content.editedActionItems.isNotEmpty;

    if (!hasEdits) {
      return const ResyncResult.success();
    }

    // 3. Build the prompt with all content
    final prompt = _buildPrompt(content);

    // 4. Call LLM to analyze and suggest updates
    final result = await llmService.generateText(prompt: prompt);
    if (!result.isSuccess) {
      return ResyncResult.failure(result.error ?? 'LLM processing failed');
    }

    // 5. Parse and apply updates
    try {
      return await _applyUpdates(result.data!, content, sessionId);
    } catch (e) {
      return ResyncResult.failure('Failed to apply updates: $e');
    }
  }

  Future<SessionContent> _collectSessionContent(
    String sessionId,
    String worldId,
  ) async {
    final summary = await summaryRepo.getSummaryBySession(sessionId);
    final scenes = await summaryRepo.getScenesBySession(sessionId);
    final actionItems = await actionItemRepo.getBySession(sessionId);

    // Get entities from world that appeared in this session
    final appearances = await entityRepo.getAppearancesBySession(sessionId);
    final npcIds =
        appearances.where((a) => a.entityType.value == 'npc').map((a) => a.entityId).toSet();
    final locationIds = appearances
        .where((a) => a.entityType.value == 'location')
        .map((a) => a.entityId)
        .toSet();
    final itemIds = appearances
        .where((a) => a.entityType.value == 'item')
        .map((a) => a.entityId)
        .toSet();

    final allNpcs = await entityRepo.getNpcsByWorld(worldId);
    final allLocations = await entityRepo.getLocationsByWorld(worldId);
    final allItems = await entityRepo.getItemsByWorld(worldId);

    return SessionContent(
      summary: summary,
      scenes: scenes,
      npcs: allNpcs.where((n) => npcIds.contains(n.id)).toList(),
      locations: allLocations.where((l) => locationIds.contains(l.id)).toList(),
      items: allItems.where((i) => itemIds.contains(i.id)).toList(),
      actionItems: actionItems,
    );
  }

  String _buildPrompt(SessionContent content) {
    // Format edited content
    final editedEntities = _formatEditedEntities(content);
    final editedSummary =
        content.summary?.isEdited == true ? content.summary!.overallSummary ?? '' : 'None';
    final editedScenes = _formatScenes(content.editedScenes);
    final editedActionItems = _formatActionItems(content.editedActionItems);

    // Format current unedited content
    final currentSummary =
        content.summary?.isEdited != true ? content.summary?.overallSummary ?? 'None' : 'None';
    final currentScenes = _formatScenes(content.uneditedScenes);
    final currentEntities = _formatCurrentEntities(content);
    final currentActionItems = _formatActionItems(content.uneditedActionItems);

    return buildResyncPrompt(
      editedEntities: editedEntities,
      editedSummary: editedSummary,
      editedScenes: editedScenes,
      editedActionItems: editedActionItems,
      editedPlayerMoments: 'None', // Player moments are less likely to affect other content
      currentSummary: currentSummary,
      currentScenes: currentScenes,
      currentEntities: currentEntities,
      currentActionItems: currentActionItems,
    );
  }

  String _formatEditedEntities(SessionContent content) {
    final buffer = StringBuffer();

    if (content.editedNpcs.isNotEmpty) {
      buffer.writeln('NPCs:');
      for (final npc in content.editedNpcs) {
        buffer.writeln('- ${npc.name}: ${npc.description ?? "No description"} (${npc.role ?? "unknown role"})');
      }
    }

    if (content.editedLocations.isNotEmpty) {
      buffer.writeln('Locations:');
      for (final loc in content.editedLocations) {
        buffer.writeln('- ${loc.name}: ${loc.description ?? "No description"} (${loc.locationType ?? "unknown type"})');
      }
    }

    if (content.editedItems.isNotEmpty) {
      buffer.writeln('Items:');
      for (final item in content.editedItems) {
        buffer.writeln('- ${item.name}: ${item.description ?? "No description"} (${item.itemType ?? "unknown type"})');
      }
    }

    return buffer.isEmpty ? 'None' : buffer.toString();
  }

  String _formatScenes(List<Scene> scenes) {
    if (scenes.isEmpty) return 'None';
    return scenes.map((s) => '- Scene ${s.sceneIndex + 1}: ${s.title ?? "Untitled"}\n  ${s.summary ?? "No summary"}').join('\n');
  }

  String _formatActionItems(List<ActionItem> items) {
    if (items.isEmpty) return 'None';
    return items.map((a) => '- [${a.status.value}] ${a.title}: ${a.description ?? "No description"}').join('\n');
  }

  String _formatCurrentEntities(SessionContent content) {
    final uneditedNpcs = content.npcs.where((n) => !n.isEdited);
    final uneditedLocs = content.locations.where((l) => !l.isEdited);
    final uneditedItems = content.items.where((i) => !i.isEdited);

    final buffer = StringBuffer();

    if (uneditedNpcs.isNotEmpty) {
      buffer.writeln('NPCs:');
      for (final npc in uneditedNpcs) {
        buffer.writeln('- ${npc.name}: ${npc.description ?? "No description"}');
      }
    }

    if (uneditedLocs.isNotEmpty) {
      buffer.writeln('Locations:');
      for (final loc in uneditedLocs) {
        buffer.writeln('- ${loc.name}: ${loc.description ?? "No description"}');
      }
    }

    if (uneditedItems.isNotEmpty) {
      buffer.writeln('Items:');
      for (final item in uneditedItems) {
        buffer.writeln('- ${item.name}: ${item.description ?? "No description"}');
      }
    }

    return buffer.isEmpty ? 'None' : buffer.toString();
  }

  Future<ResyncResult> _applyUpdates(
    String llmResponse,
    SessionContent content,
    String sessionId,
  ) async {
    // Extract JSON from response
    final jsonStr = _extractJson(llmResponse);
    if (jsonStr.isEmpty || jsonStr == '{}') {
      return const ResyncResult.success();
    }

    final updates = jsonDecode(jsonStr) as Map<String, dynamic>;
    var summaryUpdated = false;
    var scenesUpdated = 0;
    var entitiesUpdated = 0;
    var actionItemsUpdated = 0;

    // Apply summary updates (only if not already edited)
    if (updates.containsKey('summary_updates') && content.summary?.isEdited != true) {
      final summaryUpdates = updates['summary_updates'] as Map<String, dynamic>;
      if (summaryUpdates['overall_summary'] != null && content.summary != null) {
        final updated = content.summary!.copyWith(
          overallSummary: summaryUpdates['overall_summary'] as String,
          updatedAt: DateTime.now(),
        );
        await summaryRepo.updateSummary(updated);
        summaryUpdated = true;
      }
    }

    // Apply scene updates (only to unedited scenes)
    if (updates.containsKey('scene_updates')) {
      final sceneUpdates = updates['scene_updates'] as List<dynamic>;
      for (final update in sceneUpdates) {
        final sceneIndex = update['scene_index'] as int;
        final scene = content.uneditedScenes.firstWhere(
          (s) => s.sceneIndex == sceneIndex,
          orElse: () => throw Exception('Scene not found'),
        );
        final updated = scene.copyWith(
          title: update['title'] as String? ?? scene.title,
          summary: update['summary'] as String? ?? scene.summary,
          updatedAt: DateTime.now(),
        );
        await summaryRepo.updateScene(updated);
        scenesUpdated++;
      }
    }

    // Apply entity updates (only to unedited entities)
    if (updates.containsKey('entity_updates')) {
      final entityUpdates = updates['entity_updates'] as Map<String, dynamic>;

      if (entityUpdates.containsKey('npcs')) {
        for (final npcUpdate in entityUpdates['npcs'] as List<dynamic>) {
          final npcName = npcUpdate['name'] as String;
          final npc = content.npcs.firstWhere(
            (n) => n.name == npcName && !n.isEdited,
            orElse: () => throw Exception('NPC not found'),
          );
          final updated = npc.copyWith(
            description: npcUpdate['description'] as String? ?? npc.description,
            role: npcUpdate['role'] as String? ?? npc.role,
            updatedAt: DateTime.now(),
          );
          await entityRepo.updateNpc(updated);
          entitiesUpdated++;
        }
      }
    }

    // Apply action item updates (only to unedited items)
    if (updates.containsKey('action_item_updates')) {
      for (final itemUpdate in updates['action_item_updates'] as List<dynamic>) {
        final title = itemUpdate['title'] as String;
        final item = content.uneditedActionItems.firstWhere(
          (a) => a.title == title,
          orElse: () => throw Exception('Action item not found'),
        );
        final updated = item.copyWith(
          title: itemUpdate['new_title'] as String? ?? item.title,
          description: itemUpdate['new_description'] as String? ?? item.description,
          updatedAt: DateTime.now(),
        );
        await actionItemRepo.update(updated);
        actionItemsUpdated++;
      }
    }

    return ResyncResult.success(
      summaryUpdated: summaryUpdated,
      scenesUpdated: scenesUpdated,
      entitiesUpdated: entitiesUpdated,
      actionItemsUpdated: actionItemsUpdated,
    );
  }

  String _extractJson(String text) {
    // Try to find JSON in the response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0) ?? '{}';
    }
    return '{}';
  }
}
