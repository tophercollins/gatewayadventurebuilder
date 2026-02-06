import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env_config.dart';
import 'transcript_result.dart';
import 'transcription_service.dart';

/// Transcription service using Gemini Flash-Lite for Windows/Linux.
/// Sends audio as inline data and receives structured JSON transcription.
class GeminiTranscriptionService implements TranscriptionService {
  bool _isTranscribing = false;
  bool _isCancelled = false;

  static const _prompt = '''
Transcribe this audio accurately. Return ONLY valid JSON with no markdown formatting:
{"segments": [{"text": "...", "startMs": 0, "endMs": 5000}, ...]}
Each segment should be 5-15 seconds. Include all spoken words.''';

  @override
  String get modelName => 'gemini-flash-lite';

  @override
  int? get modelSizeBytes => null; // Cloud service, no local model

  @override
  int? get preferredChunkDurationMs => 120000; // 2 minutes for inline limits

  @override
  bool get isTranscribing => _isTranscribing;

  @override
  Future<bool> isReady() async {
    final key = await EnvConfig.getGeminiApiKey();
    return key != null && key.isNotEmpty;
  }

  @override
  Future<void> initialize() async {
    final key = await EnvConfig.getGeminiApiKey();
    if (key == null || key.isEmpty) {
      throw const TranscriptionException(
        TranscriptionErrorType.modelNotLoaded,
        message: 'Gemini API key not configured. '
            'Please set your API key in Settings.',
      );
    }
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

      // Get API key
      final apiKey = await EnvConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw const TranscriptionException(
          TranscriptionErrorType.modelNotLoaded,
          message: 'Gemini API key not configured.',
        );
      }

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 0,
          totalChunks: 1,
          phase: TranscriptionPhase.preparing,
          message: 'Preparing audio for Gemini...',
        ),
      );

      // Read audio bytes
      final audioBytes = await file.readAsBytes();

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 0,
          totalChunks: 1,
          phase: TranscriptionPhase.transcribing,
          message: 'Transcribing via Gemini...',
        ),
      );

      // Create model and send request
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      final content = Content.multi([
        DataPart('audio/wav', audioBytes),
        TextPart(_prompt),
      ]);

      final response = await model.generateContent([content]);

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      // Parse JSON response
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw const TranscriptionException(
          TranscriptionErrorType.processingFailed,
          message: 'Gemini returned empty response',
        );
      }

      final segments = _parseResponse(responseText);

      // Build full text
      final fullText = segments.map((s) => s.text).join(' ');

      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 1,
          totalChunks: 1,
          phase: TranscriptionPhase.complete,
          message: 'Transcription complete',
        ),
      );

      return TranscriptResult(
        fullText: fullText,
        segments: segments,
        modelName: modelName,
        language: language,
      );
    } catch (e) {
      if (e is TranscriptionException) rethrow;
      throw TranscriptionException(
        TranscriptionErrorType.processingFailed,
        message: 'Gemini transcription failed: $e',
      );
    } finally {
      _isTranscribing = false;
    }
  }

  /// Parse Gemini's JSON response into transcript segments.
  List<TranscriptSegmentData> _parseResponse(String responseText) {
    try {
      // Strip markdown code fences if present
      var cleaned = responseText.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
        cleaned = cleaned.trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final segmentsList = json['segments'] as List<dynamic>;

      return segmentsList.map((s) {
        final map = s as Map<String, dynamic>;
        return TranscriptSegmentData(
          text: (map['text'] as String).trim(),
          startTimeMs: (map['startMs'] as num).toInt(),
          endTimeMs: (map['endMs'] as num).toInt(),
        );
      }).toList();
    } catch (e) {
      throw TranscriptionException(
        TranscriptionErrorType.processingFailed,
        message: 'Failed to parse Gemini response: $e',
        details: responseText,
      );
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
  }
}
