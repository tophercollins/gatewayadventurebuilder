import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session.dart';
import '../data/repositories/session_repository.dart';
import '../services/transcription/transcription.dart';
import 'repository_providers.dart';

/// Provider for the TranscriptionService.
/// macOS: local Whisper (free, offline).
/// Windows/Linux: Gemini Flash-Lite (cloud).
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final TranscriptionService service;
  if (Platform.isMacOS) {
    service = WhisperTranscriptionService();
  } else {
    service = GeminiTranscriptionService();
  }
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
      debugPrint('[TranscriptionNotifier] Starting transcription for $sessionId');
      await _manager.transcribeSession(
        sessionId: sessionId,
        audioFilePath: audioFilePath,
        language: language,
        onProgress: _handleProgress,
      );
      debugPrint('[TranscriptionNotifier] Transcription manager returned, updating status to queued');

      // Update session status to queued (ready for AI processing)
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.queued);
      debugPrint('[TranscriptionNotifier] Status updated, setting state to complete');

      state = state.copyWith(
        phase: TranscriptionPhase.complete,
        progress: 1.0,
        message: 'Transcription complete',
        isActive: false,
        clearError: true,
      );
      debugPrint('[TranscriptionNotifier] Done');
    } on TranscriptionException catch (e) {
      debugPrint('[TranscriptionNotifier] TranscriptionException: ${e.message}');
      state = state.copyWith(
        phase: TranscriptionPhase.error,
        message: e.userMessage,
        error: e,
        isActive: false,
      );

      // Update session status to error
      await _sessionRepo.updateSessionStatus(sessionId, SessionStatus.error);
    } catch (e) {
      debugPrint('[TranscriptionNotifier] Generic error: $e');
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

/// Service for transcript mutations (save edits, revert).
class TranscriptEditor {
  TranscriptEditor(this._sessionRepo, this._ref);

  final SessionRepository _sessionRepo;
  final Ref _ref;

  /// Saves edited transcript text and refreshes data.
  Future<void> saveTranscript({
    required String transcriptId,
    required String sessionId,
    required String newText,
  }) async {
    await _sessionRepo.updateTranscriptText(transcriptId, newText);
    _ref.invalidate(sessionTranscriptProvider(sessionId));
  }

  /// Reverts transcript to original text and refreshes data.
  Future<void> revertTranscript({
    required String transcriptId,
    required String sessionId,
  }) async {
    await _sessionRepo.revertTranscriptText(transcriptId);
    _ref.invalidate(sessionTranscriptProvider(sessionId));
  }
}

/// Provider for transcript mutations.
final transcriptEditorProvider = Provider<TranscriptEditor>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return TranscriptEditor(sessionRepo, ref);
});
