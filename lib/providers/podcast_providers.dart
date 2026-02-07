import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/summary_repository.dart';
import '../services/processing/podcast_generator.dart';
import 'processing_providers.dart';
import 'session_detail_providers.dart';
import 'transcription_providers.dart';

/// Provider for PodcastGenerator service.
final podcastGeneratorProvider = Provider<PodcastGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return PodcastGenerator(llmService: llmService);
});

/// Provider that loads the saved podcast script for a session.
/// Returns null if no summary or no podcast script exists.
final podcastScriptProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, sessionId) async {
      final summaryRepo = ref.watch(summaryRepositoryProvider);
      final summary = await summaryRepo.getSummaryBySession(sessionId);
      return summary?.podcastScript;
    });

/// State for podcast generation.
class PodcastGenerationState {
  const PodcastGenerationState({this.isGenerating = false, this.error});

  final bool isGenerating;
  final String? error;

  PodcastGenerationState copyWith({bool? isGenerating, String? error}) {
    return PodcastGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

/// StateNotifier for managing podcast generation state.
class PodcastGenerationNotifier extends StateNotifier<PodcastGenerationState> {
  PodcastGenerationNotifier(this._generator, this._summaryRepo, this._ref)
    : super(const PodcastGenerationState());

  final PodcastGenerator _generator;
  final SummaryRepository _summaryRepo;
  final Ref _ref;

  /// Generate a podcast script for the given session.
  Future<void> generate({
    required String sessionId,
    required String campaignId,
  }) async {
    // Load session summary
    final summary = await _summaryRepo.getSummaryBySession(sessionId);
    if (summary == null || summary.overallSummary == null) {
      state = const PodcastGenerationState(
        error: 'No session summary available. Process the session first.',
      );
      return;
    }

    // Load transcript text
    final transcriptAsync = _ref.read(sessionTranscriptProvider(sessionId));
    final transcriptText = transcriptAsync.valueOrNull?.displayText ?? '';

    // Load campaign name and attendees from session detail
    final detailAsync = _ref.read(
      sessionDetailProvider((campaignId: campaignId, sessionId: sessionId)),
    );
    final detail = detailAsync.valueOrNull;
    final campaignName = detail?.session.title ?? 'Campaign Session';
    final attendeeNames = detail?.players.values.map((p) => p.name).toList();

    state = const PodcastGenerationState(isGenerating: true);

    final result = await _generator.generateScript(
      summary: summary.overallSummary!,
      transcript: transcriptText,
      campaignName: campaignName,
      attendeeNames: attendeeNames,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      await _summaryRepo.updatePodcastScript(summary.id, result.data!);
      state = const PodcastGenerationState();
      _ref.invalidate(podcastScriptProvider(sessionId));
    } else {
      state = PodcastGenerationState(
        error: result.error ?? 'Failed to generate podcast script',
      );
    }
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for podcast generation state management.
final podcastGenerationStateProvider =
    StateNotifierProvider.autoDispose<
      PodcastGenerationNotifier,
      PodcastGenerationState
    >((ref) {
      final generator = ref.watch(podcastGeneratorProvider);
      final summaryRepo = ref.watch(summaryRepositoryProvider);
      return PodcastGenerationNotifier(generator, summaryRepo, ref);
    });
