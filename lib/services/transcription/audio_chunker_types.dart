/// Data types for audio chunking operations.
///
/// This file contains the data classes and exceptions used by [AudioChunker].
library;

/// Information about an audio chunk for transcription.
class AudioChunk {
  const AudioChunk({
    required this.filePath,
    required this.chunkIndex,
    required this.totalChunks,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.isTemporary,
  });

  /// Path to the chunk file (may be temporary).
  final String filePath;

  /// Zero-based index of this chunk.
  final int chunkIndex;

  /// Total number of chunks.
  final int totalChunks;

  /// Start time offset in milliseconds from original audio.
  final int startTimeMs;

  /// End time offset in milliseconds from original audio.
  final int endTimeMs;

  /// Whether this file is temporary and should be deleted after use.
  final bool isTemporary;

  /// Duration of this chunk in milliseconds.
  int get durationMs => endTimeMs - startTimeMs;

  @override
  String toString() {
    return 'AudioChunk(index: $chunkIndex/$totalChunks, '
        'start: ${startTimeMs}ms, end: ${endTimeMs}ms)';
  }
}

/// WAV file format information.
class WavInfo {
  const WavInfo({
    required this.numChannels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataSize,
    required this.durationMs,
    required this.headerSize,
  });

  final int numChannels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataSize;
  final int durationMs;
  final int headerSize;
}

/// Exception thrown by AudioChunker.
class AudioChunkerException implements Exception {
  const AudioChunkerException(this.error, {this.message});

  final AudioChunkerError error;
  final String? message;

  @override
  String toString() {
    return 'AudioChunkerException: ${error.name}'
        '${message != null ? ' - $message' : ''}';
  }
}

/// Error types for AudioChunker.
enum AudioChunkerError {
  fileNotFound,
  invalidFormat,
  ioError,
}
