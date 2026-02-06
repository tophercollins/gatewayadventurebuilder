import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session.dart';
import '../data/repositories/session_repository.dart';
import 'campaign_providers.dart';
import 'recording_providers.dart';
import 'repository_providers.dart';
import 'transcription_providers.dart';

/// Phase of post-session processing.
enum PostSessionPhase { idle, savingAudio, transcribing, complete, error }

/// State for post-session processing.
class PostSessionState {
  const PostSessionState({
    this.phase = PostSessionPhase.idle,
    this.error,
    this.session,
    this.audioDurationSeconds,
    this.audioFileSizeBytes,
    this.audioFilePath,
  });

  final PostSessionPhase phase;
  final String? error;
  final Session? session;
  final int? audioDurationSeconds;
  final int? audioFileSizeBytes;
  final String? audioFilePath;

  PostSessionState copyWith({
    PostSessionPhase? phase,
    String? error,
    Session? session,
    int? audioDurationSeconds,
    int? audioFileSizeBytes,
    String? audioFilePath,
    bool clearError = false,
  }) {
    return PostSessionState(
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
      session: session ?? this.session,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      audioFileSizeBytes: audioFileSizeBytes ?? this.audioFileSizeBytes,
      audioFilePath: audioFilePath ?? this.audioFilePath,
    );
  }
}

/// Notifier for managing the post-session processing workflow.
/// Coordinates audio saving, session updates, and transcription initiation.
class PostSessionNotifier extends StateNotifier<PostSessionState> {
  PostSessionNotifier(this._sessionRepo, this._ref)
      : super(const PostSessionState());

  final SessionRepository _sessionRepo;
  final Ref _ref;

  /// Process a completed recording: save audio metadata, update session,
  /// and start transcription.
  Future<void> processRecording(String sessionId) async {
    try {
      state = const PostSessionState(phase: PostSessionPhase.savingAudio);

      final recordingState = _ref.read(recordingNotifierProvider);
      final audioService = _ref.read(audioRecordingServiceProvider);

      final filePath = recordingState.filePath ?? audioService.currentFilePath;
      if (filePath == null) throw Exception('No recording file found');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found at: $filePath');
      }

      final fileSize = await file.length();
      final duration = recordingState.elapsedTime.inSeconds;

      await _sessionRepo.createAudio(
        sessionId: sessionId,
        filePath: filePath,
        fileSizeBytes: fileSize,
        format: 'wav',
        durationSeconds: duration,
      );

      final session = await _sessionRepo.getSessionById(sessionId);
      if (session != null) {
        await _sessionRepo.updateSession(
          session.copyWith(durationSeconds: duration),
        );
        await _sessionRepo.updateSessionStatus(
          sessionId,
          SessionStatus.transcribing,
        );
      }

      final updatedSession = await _sessionRepo.getSessionById(sessionId);

      if (!mounted) return;

      state = PostSessionState(
        phase: PostSessionPhase.transcribing,
        session: updatedSession,
        audioDurationSeconds: duration,
        audioFileSizeBytes: fileSize,
        audioFilePath: filePath,
      );

      _ref.read(sessionsRevisionProvider.notifier).state++;
      await _startTranscription(sessionId, filePath);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        phase: PostSessionPhase.error,
        error: e.toString(),
      );
    }
  }

  /// Start transcription for the given audio file.
  Future<void> _startTranscription(
    String sessionId,
    String audioFilePath,
  ) async {
    try {
      final notifier = _ref.read(transcriptionNotifierProvider.notifier);
      await notifier.transcribe(
        sessionId: sessionId,
        audioFilePath: audioFilePath,
      );

      final transcriptionState = _ref.read(transcriptionNotifierProvider);
      if (transcriptionState.hasError) {
        final detail = transcriptionState.error?.message ??
            transcriptionState.error?.details;
        final msg = transcriptionState.message ?? 'Transcription failed';
        throw Exception(detail != null ? '$msg\n$detail' : msg);
      }

      final updatedSession = await _sessionRepo.getSessionById(sessionId);

      if (mounted) {
        state = state.copyWith(
          phase: PostSessionPhase.complete,
          session: updatedSession,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          phase: PostSessionPhase.error,
          error: e.toString(),
        );
      }
    }
  }

  /// Retry processing. If audio was already saved, retries transcription only.
  Future<void> retry(String sessionId) async {
    _ref.read(transcriptionNotifierProvider.notifier).reset();
    if (state.audioFilePath != null &&
        state.phase == PostSessionPhase.error) {
      state = state.copyWith(
        phase: PostSessionPhase.transcribing,
        clearError: true,
      );
      await _startTranscription(sessionId, state.audioFilePath!);
    } else {
      await processRecording(sessionId);
    }
  }
}

/// Provider for the post-session processing notifier.
final postSessionNotifierProvider =
    StateNotifierProvider.autoDispose<PostSessionNotifier, PostSessionState>((
  ref,
) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return PostSessionNotifier(sessionRepo, ref);
});
