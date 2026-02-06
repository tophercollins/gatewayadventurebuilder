import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/processing/podcast_generator.dart';
import 'processing_providers.dart';

/// Provider for PodcastGenerator service.
final podcastGeneratorProvider = Provider<PodcastGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return PodcastGenerator(llmService: llmService);
});

/// Provider that loads the saved podcast script for a session.
/// Returns null if no summary or no podcast script exists.
final podcastScriptProvider =
    FutureProvider.autoDispose.family<String?, String>((
      ref,
      sessionId,
    ) async {
      final summaryRepo = ref.watch(summaryRepositoryProvider);
      final summary = await summaryRepo.getSummaryBySession(sessionId);
      return summary?.podcastScript;
    });

/// State for podcast generation.
class PodcastGenerationState {
  const PodcastGenerationState({
    this.isGenerating = false,
    this.error,
  });

  final bool isGenerating;
  final String? error;

  PodcastGenerationState copyWith({
    bool? isGenerating,
    String? error,
  }) {
    return PodcastGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

/// StateNotifier for managing podcast generation state.
class PodcastGenerationNotifier extends StateNotifier<PodcastGenerationState> {
  PodcastGenerationNotifier() : super(const PodcastGenerationState());

  /// Set generating state.
  void setGenerating() {
    state = const PodcastGenerationState(isGenerating: true);
  }

  /// Set complete state.
  void setComplete() {
    state = const PodcastGenerationState(isGenerating: false);
  }

  /// Set error state.
  void setError(String error) {
    state = PodcastGenerationState(isGenerating: false, error: error);
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for podcast generation state management.
final podcastGenerationStateProvider = StateNotifierProvider.autoDispose<
  PodcastGenerationNotifier,
  PodcastGenerationState
>((ref) {
  return PodcastGenerationNotifier();
});
