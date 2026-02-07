import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import 'model_manager.dart';
import 'transcript_result.dart';
import 'transcription_service.dart';

/// Transcription service using local whisper.cpp via whisper_flutter_new.
/// Used on macOS for free, offline transcription.
class WhisperTranscriptionService implements TranscriptionService {
  WhisperTranscriptionService({
    this.whisperModel = 'base',
    ModelManager? modelManager,
  }) : _modelManager = modelManager ?? ModelManager();

  final String whisperModel;
  final ModelManager _modelManager;

  Whisper? _whisper;
  bool _isTranscribing = false;
  bool _isCancelled = false;

  @override
  String get modelName => 'whisper-$whisperModel';

  @override
  int? get modelSizeBytes =>
      WhisperModelInfo.getByName(whisperModel)?.sizeBytes;

  @override
  int? get preferredChunkDurationMs => null; // 30-min default is fine

  @override
  bool get isTranscribing => _isTranscribing;

  @override
  Future<bool> isReady() => _modelManager.isModelDownloaded(whisperModel);

  @override
  Future<void> initialize() async {
    final downloaded = await _modelManager.isModelDownloaded(whisperModel);
    if (!downloaded) {
      await _modelManager.downloadModel(whisperModel);
    }
  }

  /// Initialize with progress reporting for model download.
  Future<void> initializeWithProgress({
    void Function(double progress)? onDownloadProgress,
  }) async {
    final downloaded = await _modelManager.isModelDownloaded(whisperModel);
    if (!downloaded) {
      await _modelManager.downloadModel(
        whisperModel,
        onProgress: onDownloadProgress,
      );
    }
  }

  /// Map string model name to WhisperModel enum.
  WhisperModel get _whisperModelEnum {
    return switch (whisperModel) {
      'tiny' => WhisperModel.tiny,
      'base' => WhisperModel.base,
      'small' => WhisperModel.small,
      'medium' => WhisperModel.medium,
      _ => WhisperModel.base,
    };
  }

  @override
  Future<TranscriptResult> transcribe(
    String audioFilePath, {
    TranscriptionProgressCallback? onProgress,
    String language = 'en',
  }) async {
    _isTranscribing = true;
    _isCancelled = false;

    try {
      // Verify file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw const TranscriptionException(
          TranscriptionErrorType.fileNotFound,
          message: 'Audio file not found',
        );
      }

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 0,
          totalChunks: 1,
          phase: TranscriptionPhase.preparing,
          message: 'Loading Whisper model...',
        ),
      );

      // Create whisper instance (auto-downloads model if needed)
      _whisper ??= Whisper(model: _whisperModelEnum);

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 0,
          totalChunks: 1,
          phase: TranscriptionPhase.transcribing,
          message: 'Transcribing locally with Whisper...',
        ),
      );

      final fileSize = await file.length();
      debugPrint(
        '[WhisperService] Starting transcription: $audioFilePath ($fileSize bytes)',
      );

      // Run transcription in isolate
      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioFilePath,
          isTranslate: false,
          isNoTimestamps: false,
          language: language,
          threads: 4,
        ),
      );

      debugPrint(
        '[WhisperService] Whisper returned result, parsing segments...',
      );

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      // Parse segments from the result
      final segments = <TranscriptSegmentData>[];
      final transcribeSegments = result.segments;

      if (transcribeSegments != null) {
        for (final seg in transcribeSegments) {
          segments.add(
            TranscriptSegmentData(
              text: seg.text.trim(),
              startTimeMs: seg.fromTs.inMilliseconds,
              endTimeMs: seg.toTs.inMilliseconds,
            ),
          );
        }
      }

      // Build full text from segments, or fall back to result text
      final fullText = segments.isNotEmpty
          ? segments.map((s) => s.text).join(' ')
          : result.text.trim();

      debugPrint(
        '[WhisperService] Parsed ${segments.length} segments, fullText length: ${fullText.length}',
      );

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 1,
          totalChunks: 1,
          phase: TranscriptionPhase.complete,
          message: 'Transcription complete',
        ),
      );

      debugPrint('[WhisperService] Returning TranscriptResult');
      return TranscriptResult(
        fullText: fullText,
        segments: segments,
        modelName: modelName,
        language: language,
      );
    } catch (e, stack) {
      if (e is TranscriptionException) rethrow;
      debugPrint('[WhisperService] ERROR: $e');
      debugPrint('[WhisperService] Stack: $stack');
      throw TranscriptionException(
        TranscriptionErrorType.processingFailed,
        message: 'Whisper transcription failed: $e',
      );
    } finally {
      _isTranscribing = false;
    }
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
  }

  @override
  Future<void> dispose() async {
    _isCancelled = true;
    _isTranscribing = false;
    _whisper = null;
  }
}
