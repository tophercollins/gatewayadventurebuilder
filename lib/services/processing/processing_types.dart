/// Result of session processing.
class ProcessingResult {
  const ProcessingResult({
    required this.success,
    this.error,
    this.summaryId,
    this.sceneCount = 0,
    this.npcCount = 0,
    this.locationCount = 0,
    this.itemCount = 0,
    this.monsterCount = 0,
    this.organisationCount = 0,
    this.actionItemCount = 0,
    this.momentCount = 0,
  });

  final bool success;
  final String? error;
  final String? summaryId;
  final int sceneCount;
  final int npcCount;
  final int locationCount;
  final int itemCount;
  final int monsterCount;
  final int organisationCount;
  final int actionItemCount;
  final int momentCount;
}

/// Callback for processing progress updates.
typedef ProgressCallback = void Function(ProcessingStep step, double progress);

/// Processing steps for progress tracking.
enum ProcessingStep {
  loadingContext,
  generatingSummary,
  extractingScenes,
  extractingEntities,
  extractingActionItems,
  extractingPlayerMoments,
  savingResults,
  complete,
}

/// Internal stats tracking during processing.
class ProcessingStats {
  const ProcessingStats({
    this.summaryId,
    this.sceneCount = 0,
    this.npcCount = 0,
    this.locationCount = 0,
    this.itemCount = 0,
    this.monsterCount = 0,
    this.organisationCount = 0,
    this.actionItemCount = 0,
    this.momentCount = 0,
  });

  final String? summaryId;
  final int sceneCount;
  final int npcCount;
  final int locationCount;
  final int itemCount;
  final int monsterCount;
  final int organisationCount;
  final int actionItemCount;
  final int momentCount;

  ProcessingStats copyWith({
    String? summaryId,
    int? sceneCount,
    int? npcCount,
    int? locationCount,
    int? itemCount,
    int? monsterCount,
    int? organisationCount,
    int? actionItemCount,
    int? momentCount,
  }) {
    return ProcessingStats(
      summaryId: summaryId ?? this.summaryId,
      sceneCount: sceneCount ?? this.sceneCount,
      npcCount: npcCount ?? this.npcCount,
      locationCount: locationCount ?? this.locationCount,
      itemCount: itemCount ?? this.itemCount,
      monsterCount: monsterCount ?? this.monsterCount,
      organisationCount: organisationCount ?? this.organisationCount,
      actionItemCount: actionItemCount ?? this.actionItemCount,
      momentCount: momentCount ?? this.momentCount,
    );
  }
}

/// Entity counts from extraction.
class EntityCounts {
  const EntityCounts({
    required this.npcs,
    required this.locations,
    required this.items,
    required this.monsters,
    required this.organisations,
  });

  final int npcs;
  final int locations;
  final int items;
  final int monsters;
  final int organisations;
}
