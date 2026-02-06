import '../../data/repositories/campaign_import_repository.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/repositories/entity_repository.dart';
import 'entity_matcher.dart';
import 'llm_service.dart';
import 'prompts/entity_prompt.dart';

/// Result of import processing.
class ImportProcessingResult {
  const ImportProcessingResult({
    required this.success,
    this.error,
    this.npcCount = 0,
    this.locationCount = 0,
    this.itemCount = 0,
  });

  final bool success;
  final String? error;
  final int npcCount;
  final int locationCount;
  final int itemCount;
}

/// Processes campaign import text to extract entities.
class ImportProcessor {
  ImportProcessor({
    required LLMService llmService,
    required CampaignImportRepository importRepo,
    required CampaignRepository campaignRepo,
    required EntityRepository entityRepo,
  })  : _llmService = llmService,
        _importRepo = importRepo,
        _campaignRepo = campaignRepo,
        _entityRepo = entityRepo;

  final LLMService _llmService;
  final CampaignImportRepository _importRepo;
  final CampaignRepository _campaignRepo;
  final EntityRepository _entityRepo;

  /// Process a campaign import by ID.
  Future<ImportProcessingResult> processImport(String importId) async {
    try {
      // Get the import record
      final importRecord = await _importRepo.getById(importId);
      if (importRecord == null) {
        return const ImportProcessingResult(
          success: false,
          error: 'Import record not found',
        );
      }

      // Mark as processing
      await _importRepo.markProcessing(importId);

      // Get campaign and world info
      final campaignWithWorld =
          await _campaignRepo.getCampaignWithWorld(importRecord.campaignId);
      if (campaignWithWorld == null) {
        await _importRepo.markError(importId);
        return const ImportProcessingResult(
          success: false,
          error: 'Campaign not found',
        );
      }

      final campaign = campaignWithWorld.campaign;
      final world = campaignWithWorld.world;

      // Get existing entities for matching
      final existingNpcs = await _entityRepo.getNpcsByWorld(world.id);
      final existingLocations = await _entityRepo.getLocationsByWorld(world.id);
      final existingItems = await _entityRepo.getItemsByWorld(world.id);

      // Build the prompt for entity extraction
      final prompt = EntityPrompt.build(
        gameSystem: campaign.gameSystem ?? world.gameSystem ?? 'Unknown',
        campaignName: campaign.name,
        attendeeNames: [], // No attendees for imports
        existingNpcNames: existingNpcs.map((n) => n.name).toList(),
        existingLocationNames: existingLocations.map((l) => l.name).toList(),
        existingItemNames: existingItems.map((i) => i.name).toList(),
      );

      // Extract entities via LLM
      final result = await _llmService.extractEntities(
        transcript: importRecord.rawText,
        prompt: prompt,
      );

      if (!result.isSuccess || result.data == null) {
        await _importRepo.markError(importId);
        return ImportProcessingResult(
          success: false,
          error: result.error ?? 'Failed to extract entities',
        );
      }

      // Match and create entities
      final matcher = EntityMatcher(_entityRepo);

      final npcResults = await matcher.matchNpcs(
        worldId: world.id,
        extractedNpcs: result.data!.npcs,
      );

      final locationResults = await matcher.matchLocations(
        worldId: world.id,
        extractedLocations: result.data!.locations,
      );

      final itemResults = await matcher.matchItems(
        worldId: world.id,
        extractedItems: result.data!.items,
      );

      // Mark import as complete
      await _importRepo.markComplete(importId);

      return ImportProcessingResult(
        success: true,
        npcCount: npcResults.length,
        locationCount: locationResults.length,
        itemCount: itemResults.length,
      );
    } catch (e) {
      await _importRepo.markError(importId);
      return ImportProcessingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Process all pending imports.
  Future<List<ImportProcessingResult>> processPendingImports() async {
    final pending = await _importRepo.getPending();
    final results = <ImportProcessingResult>[];

    for (final import in pending) {
      final result = await processImport(import.id);
      results.add(result);
    }

    return results;
  }
}
