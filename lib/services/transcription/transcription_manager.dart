import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/transcript_segment.dart';
import '../../data/repositories/session_repository.dart';
import 'audio_chunker.dart';
import 'transcript_result.dart';
import 'transcription_service.dart';
import 'wav_resampler.dart';

/// Callback for transcription manager progress updates.
typedef TranscriptionManagerCallback =
    void Function(TranscriptionManagerProgress);

/// Progress information from TranscriptionManager.
class TranscriptionManagerProgress {
  const TranscriptionManagerProgress({
    required this.sessionId,
    required this.phase,
    this.currentChunk = 0,
    this.totalChunks = 1,
    this.message,
    this.error,
  });

  final String sessionId;
  final TranscriptionPhase phase;
  final int currentChunk;
  final int totalChunks;
  final String? message;
  final TranscriptionException? error;

  double get progress {
    if (totalChunks == 0) return 0.0;
    if (phase == TranscriptionPhase.complete) return 1.0;
    if (phase == TranscriptionPhase.error) return 0.0;
    return currentChunk / totalChunks;
  }

  int get progressPercent => (progress * 100).round();

  bool get isComplete => phase == TranscriptionPhase.complete;
  bool get hasError => phase == TranscriptionPhase.error;

  @override
  String toString() {
    return 'TranscriptionManagerProgress('
        'session: $sessionId, phase: ${phase.name}, '
        'chunk: $currentChunk/$totalChunks)';
  }
}

/// Orchestrates the full transcription workflow.
/// Handles chunking, isolate processing, and database storage.
class TranscriptionManager {
  TranscriptionManager({
    required this.transcriptionService,
    required this.sessionRepository,
    AudioChunker? audioChunker,
  }) : audioChunker = audioChunker ?? AudioChunker();

  final TranscriptionService transcriptionService;
  final SessionRepository sessionRepository;
  final AudioChunker audioChunker;

  static const _uuid = Uuid();

  bool _isCancelled = false;
  String? _currentSessionId;

  /// Current session being transcribed.
  String? get currentSessionId => _currentSessionId;

  /// Whether transcription is in progress.
  bool get isTranscribing => _currentSessionId != null;

  /// Transcribe an audio file and store results in the database.
  ///
  /// [sessionId] - ID of the session to associate with.
  /// [audioFilePath] - Path to the audio file.
  /// [onProgress] - Callback for progress updates.
  ///
  /// Returns the created SessionTranscript on success.
  Future<TranscriptResult> transcribeSession({
    required String sessionId,
    required String audioFilePath,
    TranscriptionManagerCallback? onProgress,
    String language = 'en',
  }) async {
    _isCancelled = false;
    _currentSessionId = sessionId;
    String? resampledTempPath;

    try {
      // Phase: Preparing
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.preparing,
        message: 'Preparing audio for transcription...',
      );

      // Resample audio to 16 kHz mono if needed
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.chunking,
        message: 'Preparing audio format...',
      );

      final resampleResult = await WavResampler.ensureWhisperFormat(
        audioFilePath,
      );
      if (resampleResult.isTemporary) {
        resampledTempPath = resampleResult.filePath;
      }
      final processedAudioPath = resampleResult.filePath;

      // Split audio into chunks if needed
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.chunking,
        message: 'Analyzing audio file...',
      );

      // Use service's preferred chunk duration if specified
      final preferredDuration = transcriptionService.preferredChunkDurationMs;
      final chunker = preferredDuration != null
          ? AudioChunker(chunkDurationMs: preferredDuration)
          : audioChunker;
      final chunks = await chunker.splitIfNeeded(processedAudioPath);

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      // Transcribe each chunk
      final chunkResults = <TranscriptResult>[];

      for (var i = 0; i < chunks.length; i++) {
        if (_isCancelled) {
          throw const TranscriptionException(TranscriptionErrorType.cancelled);
        }

        final chunk = chunks[i];

        _reportProgress(
          onProgress,
          sessionId,
          TranscriptionPhase.transcribing,
          currentChunk: i + 1,
          totalChunks: chunks.length,
          message: 'Transcribing chunk ${i + 1} of ${chunks.length}...',
        );

        // Transcribe this chunk
        final result = await transcriptionService.transcribe(
          chunk.filePath,
          language: language,
          onProgress: (progress) {
            // Map service progress to manager progress
            _reportProgress(
              onProgress,
              sessionId,
              progress.phase,
              currentChunk: i + 1,
              totalChunks: chunks.length,
              message: progress.message,
            );
          },
        );

        // Adjust timestamps for this chunk's offset
        final adjustedSegments = result.segments.map((segment) {
          return segment.withOffsetMs(chunk.startTimeMs);
        }).toList();

        chunkResults.add(
          TranscriptResult(
            fullText: result.fullText,
            segments: adjustedSegments,
            modelName: result.modelName,
            language: result.language,
          ),
        );
      }

      // Merge results
      debugPrint(
        '[TranscriptionManager] Merging ${chunkResults.length} chunk results',
      );
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.merging,
        message: 'Merging transcription results...',
      );

      final mergedResult = TranscriptResult.merge(
        chunkResults,
        modelName: transcriptionService.modelName,
        language: language,
      );
      debugPrint(
        '[TranscriptionManager] Merged: ${mergedResult.segments.length} segments, ${mergedResult.fullText.length} chars',
      );

      // Save to database
      debugPrint('[TranscriptionManager] Saving to database...');
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.saving,
        message: 'Saving transcript...',
      );

      await _saveToDatabase(sessionId, mergedResult);
      debugPrint('[TranscriptionManager] Database save complete');

      // Cleanup temporary files
      await audioChunker.cleanup();
      await _cleanupTempFile(resampledTempPath);
      debugPrint('[TranscriptionManager] Cleanup complete');

      // Complete
      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.complete,
        message: 'Transcription complete',
      );

      debugPrint('[TranscriptionManager] Transcription fully complete');
      return mergedResult;
    } catch (e, stack) {
      // Cleanup on error
      await audioChunker.cleanup();
      await _cleanupTempFile(resampledTempPath);

      debugPrint('[TranscriptionManager] ERROR: $e');
      debugPrint('[TranscriptionManager] Stack: $stack');

      if (e is TranscriptionException) {
        _reportProgress(
          onProgress,
          sessionId,
          TranscriptionPhase.error,
          message: e.userMessage,
          error: e,
        );
        rethrow;
      }

      final exception = TranscriptionException(
        TranscriptionErrorType.unknown,
        message: e.toString(),
      );

      _reportProgress(
        onProgress,
        sessionId,
        TranscriptionPhase.error,
        message: exception.userMessage,
        error: exception,
      );

      throw exception;
    } finally {
      _currentSessionId = null;
    }
  }

  /// Cancel the current transcription.
  Future<void> cancel() async {
    _isCancelled = true;
    await transcriptionService.cancel();
  }

  /// Save transcription result to the database.
  Future<void> _saveToDatabase(
    String sessionId,
    TranscriptResult result,
  ) async {
    // Create transcript record
    final transcript = await sessionRepository.createTranscript(
      sessionId: sessionId,
      rawText: result.fullText,
      whisperModel: result.modelName,
      language: result.language,
    );

    // Create segment records
    final segments = result.segments.asMap().entries.map((entry) {
      return TranscriptSegment(
        id: _uuid.v4(),
        transcriptId: transcript.id,
        segmentIndex: entry.key,
        startTimeMs: entry.value.startTimeMs,
        endTimeMs: entry.value.endTimeMs,
        text: entry.value.text,
      );
    }).toList();

    await sessionRepository.createSegments(segments);
  }

  Future<void> _cleanupTempFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _reportProgress(
    TranscriptionManagerCallback? callback,
    String sessionId,
    TranscriptionPhase phase, {
    int currentChunk = 0,
    int totalChunks = 1,
    String? message,
    TranscriptionException? error,
  }) {
    callback?.call(
      TranscriptionManagerProgress(
        sessionId: sessionId,
        phase: phase,
        currentChunk: currentChunk,
        totalChunks: totalChunks,
        message: message,
        error: error,
      ),
    );
  }
}
