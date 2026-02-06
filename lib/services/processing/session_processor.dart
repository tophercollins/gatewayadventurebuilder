import 'package:uuid/uuid.dart';

import '../../data/models/scene.dart';
import '../../data/models/session.dart';
import '../../data/repositories/action_item_repository.dart';
import '../../data/repositories/entity_repository.dart';
import '../../data/repositories/player_moment_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/summary_repository.dart';
import 'entity_matcher.dart';
import 'llm_service.dart';
import 'processing_types.dart';
import 'prompts/prompts.dart';
import 'session_context.dart';

/// Processes session transcripts through the AI pipeline.
class SessionProcessor {
  SessionProcessor({
    required LLMService llmService,
    required SessionRepository sessionRepo,
    required SummaryRepository summaryRepo,
    required EntityRepository entityRepo,
    required ActionItemRepository actionItemRepo,
    required PlayerMomentRepository momentRepo,
    required SessionContextLoader contextLoader,
  }) : _llmService = llmService,
       _sessionRepo = sessionRepo,
       _summaryRepo = summaryRepo,
       _entityRepo = entityRepo,
       _actionItemRepo = actionItemRepo,
       _momentRepo = momentRepo,
       _contextLoader = contextLoader;

  final LLMService _llmService;
  final SessionRepository _sessionRepo;
  final SummaryRepository _summaryRepo;
  final EntityRepository _entityRepo;
  final ActionItemRepository _actionItemRepo;
  final PlayerMomentRepository _momentRepo;
  final SessionContextLoader _contextLoader;

  static const _uuid = Uuid();

  /// Process a session by ID.
  Future<ProcessingResult> processSession(
    String sessionId, {
    ProgressCallback? onProgress,
  }) async {
    try {
      await _sessionRepo.updateSessionStatus(
        sessionId,
        SessionStatus.processing,
      );

      onProgress?.call(ProcessingStep.loadingContext, 0.0);
      final context = await _contextLoader.load(sessionId);
      if (context == null) {
        return const ProcessingResult(
          success: false,
          error: 'Failed to load session context',
        );
      }

      final transcript = context.transcript.rawText;
      var stats = const ProcessingStats();

      onProgress?.call(ProcessingStep.generatingSummary, 0.1);
      final summaryResult = await _generateSummary(context, transcript);
      stats = stats.copyWith(summaryId: summaryResult);

      onProgress?.call(ProcessingStep.extractingScenes, 0.25);
      final sceneCount = await _extractScenes(context, transcript);
      stats = stats.copyWith(sceneCount: sceneCount);

      onProgress?.call(ProcessingStep.extractingEntities, 0.4);
      final entityCounts = await _extractEntities(context, transcript);
      stats = stats.copyWith(
        npcCount: entityCounts.npcs,
        locationCount: entityCounts.locations,
        itemCount: entityCounts.items,
      );

      onProgress?.call(ProcessingStep.extractingActionItems, 0.6);
      final actionCount = await _extractActionItems(context, transcript);
      stats = stats.copyWith(actionItemCount: actionCount);

      onProgress?.call(ProcessingStep.extractingPlayerMoments, 0.8);
      final momentCount = await _extractPlayerMoments(context, transcript);
      stats = stats.copyWith(momentCount: momentCount);

      onProgress?.call(ProcessingStep.savingResults, 0.95);
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.complete);

      onProgress?.call(ProcessingStep.complete, 1.0);
      return ProcessingResult(
        success: true,
        summaryId: stats.summaryId,
        sceneCount: stats.sceneCount,
        npcCount: stats.npcCount,
        locationCount: stats.locationCount,
        itemCount: stats.itemCount,
        actionItemCount: stats.actionItemCount,
        momentCount: stats.momentCount,
      );
    } catch (e) {
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.error);
      return ProcessingResult(success: false, error: e.toString());
    }
  }

  Future<String?> _generateSummary(
    SessionContext ctx,
    String transcript,
  ) async {
    final prompt = SummaryPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
    );

    final result = await _llmService.generateSummary(
      transcript: transcript,
      prompt: prompt,
    );

    if (!result.isSuccess || result.data == null) return null;

    final summary = await _summaryRepo.createSummary(
      sessionId: ctx.session.id,
      transcriptId: ctx.transcript.id,
      overallSummary: result.data!.overallSummary,
    );
    return summary.id;
  }

  Future<int> _extractScenes(SessionContext ctx, String transcript) async {
    final prompt = ScenePrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      sessionDurationMs: ctx.session.durationSeconds != null
          ? ctx.session.durationSeconds! * 1000
          : null,
    );

    final result = await _llmService.extractScenes(
      transcript: transcript,
      prompt: prompt,
    );

    if (!result.isSuccess || result.data == null) return 0;

    final now = DateTime.now();
    final scenes = result.data!.scenes.asMap().entries.map((entry) {
      return Scene(
        id: _uuid.v4(),
        sessionId: ctx.session.id,
        sceneIndex: entry.key,
        title: entry.value.title,
        summary: entry.value.summary,
        startTimeMs: entry.value.startTimeMs,
        endTimeMs: entry.value.endTimeMs,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    await _summaryRepo.createScenes(scenes);
    return scenes.length;
  }

  Future<EntityCounts> _extractEntities(
    SessionContext ctx,
    String transcript,
  ) async {
    final prompt = EntityPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      existingNpcNames: ctx.existingNpcNames,
      existingLocationNames: ctx.existingLocationNames,
      existingItemNames: ctx.existingItemNames,
    );

    final result = await _llmService.extractEntities(
      transcript: transcript,
      prompt: prompt,
    );

    if (!result.isSuccess || result.data == null) {
      return const EntityCounts(npcs: 0, locations: 0, items: 0);
    }

    final matcher = EntityMatcher(_entityRepo);

    final npcResults = await matcher.matchNpcs(
      worldId: ctx.world.id,
      extractedNpcs: result.data!.npcs,
    );

    final locationResults = await matcher.matchLocations(
      worldId: ctx.world.id,
      extractedLocations: result.data!.locations,
    );

    final itemResults = await matcher.matchItems(
      worldId: ctx.world.id,
      extractedItems: result.data!.items,
    );

    await matcher.createAppearances(
      sessionId: ctx.session.id,
      npcs: npcResults,
      locations: locationResults,
      items: itemResults,
      npcData: result.data!.npcs,
      locationData: result.data!.locations,
      itemData: result.data!.items,
    );

    return EntityCounts(
      npcs: npcResults.length,
      locations: locationResults.length,
      items: itemResults.length,
    );
  }

  Future<int> _extractActionItems(SessionContext ctx, String transcript) async {
    final openItems = await _actionItemRepo.getOpenByCampaign(ctx.campaign.id);
    final prompt = ActionItemsPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendeeNames: ctx.attendeeNames,
      existingOpenItems: openItems.map((i) => i.title).toList(),
    );

    final result = await _llmService.extractActionItems(
      transcript: transcript,
      prompt: prompt,
    );

    if (!result.isSuccess || result.data == null) return 0;

    var count = 0;
    for (final item in result.data!.actionItems) {
      await _actionItemRepo.create(
        sessionId: ctx.session.id,
        campaignId: ctx.campaign.id,
        title: item.title,
        description: item.description,
        actionType: item.actionType,
      );
      count++;
    }
    return count;
  }

  Future<int> _extractPlayerMoments(
    SessionContext ctx,
    String transcript,
  ) async {
    final prompt = PlayerMomentsPrompt.build(
      gameSystem: ctx.gameSystem,
      campaignName: ctx.campaign.name,
      attendees: ctx.attendeeInfo,
    );

    final result = await _llmService.extractPlayerMoments(
      transcript: transcript,
      prompt: prompt,
    );

    if (!result.isSuccess || result.data == null) return 0;

    var count = 0;
    for (final moment in result.data!.moments) {
      final player = ctx.players
          .where((p) => p.name.toLowerCase() == moment.playerName.toLowerCase())
          .firstOrNull;
      if (player == null) continue;

      String? characterId;
      if (moment.characterName != null) {
        final character = ctx.characters
            .where(
              (c) =>
                  c.name.toLowerCase() == moment.characterName!.toLowerCase(),
            )
            .firstOrNull;
        characterId = character?.id;
      }

      await _momentRepo.create(
        sessionId: ctx.session.id,
        playerId: player.id,
        characterId: characterId,
        momentType: moment.momentType,
        description: moment.description,
        quoteText: moment.quoteText,
        timestampMs: moment.timestampMs,
      );
      count++;
    }
    return count;
  }
}
