import 'entity_matcher.dart';
import 'llm_service.dart';
import 'processing_types.dart';
import 'prompts/prompts.dart';
import 'session_context.dart';

/// Orchestrates entity extraction via 3 dedicated LLM calls.
class EntityExtractor {
  EntityExtractor({
    required LLMService llmService,
    required EntityMatcher entityMatcher,
  }) : _llmService = llmService,
       _entityMatcher = entityMatcher;

  final LLMService _llmService;
  final EntityMatcher _entityMatcher;

  /// Extract entities using 3 separate LLM calls (NPCs, locations, items).
  /// Calls run sequentially to avoid rate limiting.
  Future<EntityCounts> extract({
    required SessionContext ctx,
    required String transcript,
    ProgressCallback? onProgress,
  }) async {
    // 1. Extract NPCs
    onProgress?.call(ProcessingStep.extractingEntities, 0.40);
    final npcPrompt = NpcPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      existingNpcNames: ctx.existingNpcNames,
    );
    final npcResult = await _llmService.extractNpcs(
      transcript: transcript,
      prompt: npcPrompt,
    );

    // 2. Extract locations
    onProgress?.call(ProcessingStep.extractingEntities, 0.47);
    final locPrompt = LocationPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      existingLocationNames: ctx.existingLocationNames,
    );
    final locResult = await _llmService.extractLocations(
      transcript: transcript,
      prompt: locPrompt,
    );

    // 3. Extract items
    onProgress?.call(ProcessingStep.extractingEntities, 0.54);
    final itemPrompt = ItemPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      existingItemNames: ctx.existingItemNames,
    );
    final itemResult = await _llmService.extractItems(
      transcript: transcript,
      prompt: itemPrompt,
    );

    // Match and persist
    final npcMatches = await _entityMatcher.matchNpcs(
      worldId: ctx.world.id,
      extractedNpcs: npcResult.data?.npcs ?? [],
    );
    final locMatches = await _entityMatcher.matchLocations(
      worldId: ctx.world.id,
      extractedLocations: locResult.data?.locations ?? [],
    );
    final itemMatches = await _entityMatcher.matchItems(
      worldId: ctx.world.id,
      extractedItems: itemResult.data?.items ?? [],
    );

    await _entityMatcher.createAppearances(
      sessionId: ctx.session.id,
      npcs: npcMatches,
      locations: locMatches,
      items: itemMatches,
      npcData: npcResult.data?.npcs ?? [],
      locationData: locResult.data?.locations ?? [],
      itemData: itemResult.data?.items ?? [],
    );

    return EntityCounts(
      npcs: npcMatches.length,
      locations: locMatches.length,
      items: itemMatches.length,
    );
  }
}
