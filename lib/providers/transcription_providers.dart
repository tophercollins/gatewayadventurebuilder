import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session.dart';
import '../data/repositories/session_repository.dart';
import '../services/transcription/transcription.dart';
import 'repository_providers.dart';

/// Provider for the TranscriptionService (mock for MVP).
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final service = MockTranscriptionService(
    simulateDelay: true,
    delayFactor: 0.05, // 5% of audio duration as delay
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for the TranscriptionManager.
final transcriptionManagerProvider = Provider<TranscriptionManager>((ref) {
  final service = ref.watch(transcriptionServiceProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);

  return TranscriptionManager(
    transcriptionService: service,
    sessionRepository: sessionRepo,
  );
});

/// State for tracking transcription progress.
class TranscriptionState {
  const TranscriptionState({
    this.sessionId,
    this.phase = TranscriptionPhase.preparing,
    this.progress = 0.0,
    this.message,
    this.error,
    this.isActive = false,
  });

  /// ID of the session being transcribed.
  final String? sessionId;

  /// Current transcription phase.
  final TranscriptionPhase phase;

  /// Progress value between 0.0 and 1.0.
  final double progress;

  /// Status message for display.
  final String? message;

  /// Error if transcription failed.
  final TranscriptionException? error;

  /// Whether transcription is currently active.
  final bool isActive;

  /// Progress as a percentage (0-100).
  int get progressPercent => (progress * 100).round();

  /// Whether transcription completed successfully.
  bool get isComplete => phase == TranscriptionPhase.complete;

  /// Whether transcription has an error.
  bool get hasError => error != null || phase == TranscriptionPhase.error;

  TranscriptionState copyWith({
    String? sessionId,
    TranscriptionPhase? phase,
    double? progress,
    String? message,
    TranscriptionException? error,
    bool? isActive,
    bool clearError = false,
    bool clearSessionId = false,
  }) {
    return TranscriptionState(
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'TranscriptionState('
        'session: $sessionId, phase: ${phase.name}, '
        'progress: $progressPercent%, active: $isActive)';
  }
}

/// Notifier for managing transcription state.
class TranscriptionNotifier extends StateNotifier<TranscriptionState> {
  TranscriptionNotifier(this._manager, this._sessionRepo)
    : super(const TranscriptionState());

  final TranscriptionManager _manager;
  final SessionRepository _sessionRepo;

  /// Start transcribing a session.
  Future<void> transcribe({
    required String sessionId,
    required String audioFilePath,
    String language = 'en',
  }) async {
    // Update state to active
    state = state.copyWith(
      sessionId: sessionId,
      phase: TranscriptionPhase.preparing,
      progress: 0.0,
      message: 'Starting transcription...',
      isActive: true,
      clearError: true,
    );

    try {
      await _manager.transcribeSession(
        sessionId: sessionId,
        audioFilePath: audioFilePath,
        language: language,
        onProgress: _handleProgress,
      );

      // Update session status to queued (ready for AI processing)
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.queued);

      state = state.copyWith(
        phase: TranscriptionPhase.complete,
        progress: 1.0,
        message: 'Transcription complete',
        isActive: false,
      );
    } on TranscriptionException catch (e) {
      state = state.copyWith(
        phase: TranscriptionPhase.error,
        message: e.userMessage,
        error: e,
        isActive: false,
      );

      // Update session status to error
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.error);
    } catch (e) {
      final error = TranscriptionException(
        TranscriptionErrorType.unknown,
        message: e.toString(),
      );

      state = state.copyWith(
        phase: TranscriptionPhase.error,
        message: error.userMessage,
        error: error,
        isActive: false,
      );

      // Update session status to error
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.error);
    }
  }

  /// Cancel the current transcription.
  Future<void> cancel() async {
    await _manager.cancel();
    state = state.copyWith(
      phase: TranscriptionPhase.error,
      message: 'Transcription cancelled',
      isActive: false,
    );
  }

  /// Reset the transcription state.
  void reset() {
    state = const TranscriptionState();
  }

  void _handleProgress(TranscriptionManagerProgress progress) {
    state = state.copyWith(
      sessionId: progress.sessionId,
      phase: progress.phase,
      progress: progress.progress,
      message: progress.message,
      error: progress.error,
    );
  }
}

/// Provider for the TranscriptionNotifier.
final transcriptionNotifierProvider =
    StateNotifierProvider<TranscriptionNotifier, TranscriptionState>((ref) {
      final manager = ref.watch(transcriptionManagerProvider);
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      return TranscriptionNotifier(manager, sessionRepo);
    });

/// Provider for checking if a session has a transcript.
final sessionHasTranscriptProvider = FutureProvider.family<bool, String>((
  ref,
  sessionId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final transcript = await sessionRepo.getLatestTranscript(sessionId);
  return transcript != null;
});

/// Provider for getting the latest transcript for a session.
final sessionTranscriptProvider = FutureProvider.family((
  ref,
  String sessionId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return sessionRepo.getLatestTranscript(sessionId);
});

/// Provider for getting transcript segments for a session.
final transcriptSegmentsProvider = FutureProvider.family((
  ref,
  String transcriptId,
) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return sessionRepo.getSegmentsByTranscript(transcriptId);
});
