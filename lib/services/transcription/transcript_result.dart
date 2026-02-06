/// Data class representing a single segment of transcribed audio.
/// Contains timestamped text for a portion of the transcript.
class TranscriptSegmentData {
  const TranscriptSegmentData({
    required this.text,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  /// The transcribed text for this segment.
  final String text;

  /// Start timestamp in milliseconds from audio start.
  final int startTimeMs;

  /// End timestamp in milliseconds from audio start.
  final int endTimeMs;

  /// Duration of this segment in milliseconds.
  int get durationMs => endTimeMs - startTimeMs;

  /// Create a copy with adjusted timestamps (for chunk merging).
  TranscriptSegmentData withOffsetMs(int offsetMs) {
    return TranscriptSegmentData(
      text: text,
      startTimeMs: startTimeMs + offsetMs,
      endTimeMs: endTimeMs + offsetMs,
    );
  }

  @override
  String toString() {
    return 'TranscriptSegmentData('
        'text: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}", '
        'start: ${startTimeMs}ms, end: ${endTimeMs}ms)';
  }
}

/// Result of a transcription operation.
/// Contains the full transcript text and timestamped segments.
class TranscriptResult {
  const TranscriptResult({
    required this.fullText,
    required this.segments,
    required this.modelName,
    this.language = 'en',
    this.processingTimeMs,
  });

  /// The complete transcribed text.
  final String fullText;

  /// List of timestamped segments.
  final List<TranscriptSegmentData> segments;

  /// The Whisper model used (e.g., 'base', 'small', 'mock').
  final String modelName;

  /// Detected or configured language code.
  final String language;

  /// Time taken to process in milliseconds (optional).
  final int? processingTimeMs;

  /// Total duration of the transcribed audio in milliseconds.
  int get totalDurationMs {
    if (segments.isEmpty) return 0;
    return segments.last.endTimeMs;
  }

  /// Number of segments in the transcript.
  int get segmentCount => segments.length;

  /// Create an empty result (for error cases or no audio).
  factory TranscriptResult.empty({String modelName = 'unknown'}) {
    return TranscriptResult(
      fullText: '',
      segments: const [],
      modelName: modelName,
    );
  }

  /// Merge multiple transcript results (for chunked processing).
  /// Each result should already have corrected timestamps.
  factory TranscriptResult.merge(
    List<TranscriptResult> results, {
    required String modelName,
    String language = 'en',
  }) {
    if (results.isEmpty) {
      return TranscriptResult.empty(modelName: modelName);
    }

    final allSegments = <TranscriptSegmentData>[];
    final textBuffer = StringBuffer();

    for (final result in results) {
      if (textBuffer.isNotEmpty && result.fullText.isNotEmpty) {
        textBuffer.write(' ');
      }
      textBuffer.write(result.fullText);
      allSegments.addAll(result.segments);
    }

    return TranscriptResult(
      fullText: textBuffer.toString(),
      segments: allSegments,
      modelName: modelName,
      language: language,
    );
  }

  @override
  String toString() {
    return 'TranscriptResult('
        'segments: $segmentCount, '
        'duration: ${totalDurationMs}ms, '
        'model: $modelName, '
        'language: $language)';
  }
}

/// Progress information during transcription.
class TranscriptionProgress {
  const TranscriptionProgress({
    required this.currentChunk,
    required this.totalChunks,
    required this.phase,
    this.message,
  });

  /// Current chunk being processed (1-indexed).
  final int currentChunk;

  /// Total number of chunks to process.
  final int totalChunks;

  /// Current processing phase.
  final TranscriptionPhase phase;

  /// Optional status message.
  final String? message;

  /// Progress as a value between 0.0 and 1.0.
  double get progress {
    if (totalChunks == 0) return 0.0;
    return currentChunk / totalChunks;
  }

  /// Progress as a percentage (0-100).
  int get progressPercent => (progress * 100).round();

  @override
  String toString() {
    return 'TranscriptionProgress('
        'chunk: $currentChunk/$totalChunks, '
        'phase: ${phase.name}, '
        'progress: $progressPercent%)';
  }
}

/// Phases of the transcription process.
enum TranscriptionPhase {
  /// Preparing audio file for processing.
  preparing,

  /// Splitting audio into chunks.
  chunking,

  /// Actively transcribing audio.
  transcribing,

  /// Merging chunk results.
  merging,

  /// Saving to database.
  saving,

  /// Transcription complete.
  complete,

  /// An error occurred.
  error,
}
