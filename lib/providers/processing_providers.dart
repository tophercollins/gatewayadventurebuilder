import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/campaign_import_repository.dart';
import '../data/repositories/processing_queue_repository.dart';
import '../data/repositories/summary_repository.dart';
import '../services/notifications/notification_service.dart';
import '../services/processing/import_processor.dart';
import '../services/processing/llm_service.dart';
import '../services/processing/processing_types.dart';
import '../services/processing/session_context.dart';
import '../services/processing/session_processor.dart';
import 'database_provider.dart';
import 'notification_providers.dart';
import 'repository_providers.dart';

/// Provider for SummaryRepository.
final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SummaryRepository(db);
});

/// Provider for ProcessingQueueRepository.
final processingQueueRepositoryProvider = Provider<ProcessingQueueRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return ProcessingQueueRepository(db);
});

/// Provider for CampaignImportRepository.
final campaignImportRepositoryProvider = Provider<CampaignImportRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return CampaignImportRepository(db);
});

/// Provider for LLMService (Gemini by default).
final llmServiceProvider = Provider<LLMService>((ref) {
  return GeminiService();
});

/// Provider for SessionContextLoader.
final sessionContextLoaderProvider = Provider<SessionContextLoader>((ref) {
  return SessionContextLoader(
    sessionRepo: ref.watch(sessionRepositoryProvider),
    campaignRepo: ref.watch(campaignRepositoryProvider),
    playerRepo: ref.watch(playerRepositoryProvider),
    entityRepo: ref.watch(entityRepositoryProvider),
  );
});

/// Provider for SessionProcessor.
final sessionProcessorProvider = Provider<SessionProcessor>((ref) {
  return SessionProcessor(
    llmService: ref.watch(llmServiceProvider),
    sessionRepo: ref.watch(sessionRepositoryProvider),
    summaryRepo: ref.watch(summaryRepositoryProvider),
    entityRepo: ref.watch(entityRepositoryProvider),
    actionItemRepo: ref.watch(actionItemRepositoryProvider),
    momentRepo: ref.watch(playerMomentRepositoryProvider),
    contextLoader: ref.watch(sessionContextLoaderProvider),
  );
});

/// State for tracking processing progress.
class ProcessingState {
  const ProcessingState({
    this.isProcessing = false,
    this.currentSessionId,
    this.currentStep,
    this.progress = 0.0,
    this.error,
  });

  final bool isProcessing;
  final String? currentSessionId;
  final ProcessingStep? currentStep;
  final double progress;
  final String? error;

  ProcessingState copyWith({
    bool? isProcessing,
    String? currentSessionId,
    ProcessingStep? currentStep,
    double? progress,
    String? error,
  }) {
    return ProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  /// Get human-readable step description.
  String get stepDescription {
    switch (currentStep) {
      case ProcessingStep.loadingContext:
        return 'Loading session data...';
      case ProcessingStep.generatingSummary:
        return 'Generating summary...';
      case ProcessingStep.extractingScenes:
        return 'Identifying scenes...';
      case ProcessingStep.extractingEntities:
        return 'Extracting NPCs, locations, and items...';
      case ProcessingStep.extractingActionItems:
        return 'Finding action items...';
      case ProcessingStep.extractingPlayerMoments:
        return 'Capturing player moments...';
      case ProcessingStep.savingResults:
        return 'Saving results...';
      case ProcessingStep.complete:
        return 'Processing complete';
      case null:
        return '';
    }
  }
}

/// Callback type for notification after processing.
typedef OnProcessingComplete = Future<void> Function(
  String sessionId,
  ProcessingResult result,
);

/// Notifier for managing processing state.
class ProcessingStateNotifier extends StateNotifier<ProcessingState> {
  ProcessingStateNotifier({
    required SessionProcessor processor,
    OnProcessingComplete? onComplete,
  }) : _processor = processor,
       _onComplete = onComplete,
       super(const ProcessingState());

  final SessionProcessor _processor;
  final OnProcessingComplete? _onComplete;

  /// Process a session.
  Future<ProcessingResult> processSession(String sessionId) async {
    state = ProcessingState(
      isProcessing: true,
      currentSessionId: sessionId,
      currentStep: ProcessingStep.loadingContext,
      progress: 0.0,
    );

    final result = await _processor.processSession(
      sessionId,
      onProgress: (step, progress) {
        state = state.copyWith(currentStep: step, progress: progress);
      },
    );

    if (result.success) {
      state = const ProcessingState(isProcessing: false);
      // Trigger notification callback
      try {
        await _onComplete?.call(sessionId, result);
      } catch (_) {
        // Notification failures should not affect processing result.
      }
    } else {
      state = ProcessingState(isProcessing: false, error: result.error);
    }

    return result;
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for processing state management.
final processingStateProvider =
    StateNotifierProvider<ProcessingStateNotifier, ProcessingState>((ref) {
      final processor = ref.watch(sessionProcessorProvider);
      final notificationService = ref.watch(notificationServiceProvider);
      final settings = ref.watch(notificationSettingsProvider);
      final summaryRepo = ref.watch(summaryRepositoryProvider);
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      final campaignRepo = ref.watch(campaignRepositoryProvider);
      final inAppNotifier = ref.watch(inAppNotificationProvider.notifier);

      return ProcessingStateNotifier(
        processor: processor,
        onComplete: (sessionId, result) async {
          // Show in-app notification
          final session = await sessionRepo.getSessionById(sessionId);
          if (session != null) {
            inAppNotifier.showProcessingComplete(
              sessionId: sessionId,
              sessionTitle: session.title ?? 'Session ${session.sessionNumber}',
            );
          }

          // Send email notification if configured
          if (settings.isConfigured) {
            try {
              final summary = await summaryRepo.getSummaryBySession(sessionId);
              if (session != null && summary != null) {
                final campaign = await campaignRepo.getCampaignById(
                  session.campaignId,
                );
                final transcript = await sessionRepo.getLatestTranscript(
                  sessionId,
                );
                if (campaign != null) {
                  await notificationService.notifySessionProcessed(
                    settings: settings,
                    campaign: campaign,
                    session: session,
                    summary: summary,
                    durationSeconds: session.durationSeconds,
                    sceneCount: result.sceneCount,
                    npcCount: result.npcCount,
                    locationCount: result.locationCount,
                    itemCount: result.itemCount,
                    actionItemCount: result.actionItemCount,
                    momentCount: result.momentCount,
                    transcript: transcript?.displayText,
                  );
                }
              }
            } catch (_) {
              // Email failures should not block the user
            }
          }
        },
      );
    });

/// Provider to check if LLM service is available.
final llmAvailableProvider = FutureProvider<bool>((ref) async {
  final llmService = ref.watch(llmServiceProvider);
  return await llmService.isAvailable();
});

/// Provider to get pending processing queue count.
final pendingProcessingCountProvider = FutureProvider<int>((ref) async {
  final queueRepo = ref.watch(processingQueueRepositoryProvider);
  return await queueRepo.getPendingCount();
});

/// Provider for ImportProcessor.
final importProcessorProvider = Provider<ImportProcessor>((ref) {
  return ImportProcessor(
    llmService: ref.watch(llmServiceProvider),
    importRepo: ref.watch(campaignImportRepositoryProvider),
    campaignRepo: ref.watch(campaignRepositoryProvider),
    entityRepo: ref.watch(entityRepositoryProvider),
  );
});

/// Provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(emailService: ref.watch(emailServiceProvider));
});
