import 'transcript_result.dart';

/// Callback for transcription progress updates.
typedef TranscriptionProgressCallback = void Function(TranscriptionProgress);

/// Abstract interface for transcription services.
/// Allows swapping implementations (mock, local whisper.cpp, cloud API).
abstract class TranscriptionService {
  /// Get the model name used by this service.
  String get modelName;

  /// Get the model size in bytes (approximate).
  /// Returns null if model is not downloaded or size unknown.
  int? get modelSizeBytes;

  /// Check if the transcription service is ready to use.
  /// For local whisper, checks if model is downloaded.
  /// For mock, always returns true.
  Future<bool> isReady();

  /// Initialize the service and any required resources.
  /// Should be called before first use.
  Future<void> initialize();

  /// Transcribe an audio file to text with timestamps.
  ///
  /// [audioFilePath] - Path to the audio file (WAV format preferred).
  /// [onProgress] - Optional callback for progress updates.
  /// [language] - Language code (default 'en' for English).
  ///
  /// Returns a [TranscriptResult] containing the transcript and segments.
  /// Throws [TranscriptionException] on errors.
  Future<TranscriptResult> transcribe(
    String audioFilePath, {
    TranscriptionProgressCallback? onProgress,
    String language = 'en',
  });

  /// Cancel any ongoing transcription.
  /// Safe to call even if no transcription is running.
  Future<void> cancel();

  /// Release any resources held by the service.
  Future<void> dispose();

  /// Check if transcription is currently in progress.
  bool get isTranscribing;
}

/// Exception thrown when transcription fails.
class TranscriptionException implements Exception {
  const TranscriptionException(this.type, {this.message, this.details});

  /// The type of error that occurred.
  final TranscriptionErrorType type;

  /// Human-readable error message.
  final String? message;

  /// Additional error details (e.g., stack trace, error codes).
  final String? details;

  @override
  String toString() {
    final buffer = StringBuffer('TranscriptionException: ${type.name}');
    if (message != null) {
      buffer.write(' - $message');
    }
    return buffer.toString();
  }

  /// Get a user-friendly error message.
  String get userMessage {
    return switch (type) {
      TranscriptionErrorType.fileNotFound =>
        'The audio file could not be found. '
            'Please ensure the recording was saved correctly.',
      TranscriptionErrorType.invalidFormat =>
        'The audio file format is not supported. '
            'Please use WAV format for best results.',
      TranscriptionErrorType.modelNotLoaded =>
        'The transcription model is not ready. '
            'Please wait for initialization to complete.',
      TranscriptionErrorType.outOfMemory =>
        'Not enough memory to process the audio. '
            'Try closing other applications.',
      TranscriptionErrorType.processingFailed =>
        'Failed to process the audio file. '
            'Please try again.',
      TranscriptionErrorType.cancelled => 'Transcription was cancelled.',
      TranscriptionErrorType.unknown =>
        'An unexpected error occurred during transcription. '
            'Please try again.',
    };
  }
}

/// Types of transcription errors.
enum TranscriptionErrorType {
  /// Audio file not found at specified path.
  fileNotFound,

  /// Audio file format not supported or corrupted.
  invalidFormat,

  /// Whisper model not loaded or initialized.
  modelNotLoaded,

  /// Insufficient memory to process audio.
  outOfMemory,

  /// General processing failure.
  processingFailed,

  /// Transcription was cancelled by user.
  cancelled,

  /// Unknown or unexpected error.
  unknown,
}

/// Information about a Whisper model.
class WhisperModelInfo {
  const WhisperModelInfo({
    required this.name,
    required this.sizeBytes,
    required this.description,
  });

  /// Model identifier (e.g., 'base', 'small', 'medium').
  final String name;

  /// Approximate size in bytes.
  final int sizeBytes;

  /// Human-readable description.
  final String description;

  /// Size in megabytes.
  double get sizeMB => sizeBytes / (1024 * 1024);

  /// Available Whisper models for reference.
  static const List<WhisperModelInfo> availableModels = [
    WhisperModelInfo(
      name: 'tiny',
      sizeBytes: 75 * 1024 * 1024, // ~75MB
      description: 'Fastest, lowest accuracy. Good for quick tests.',
    ),
    WhisperModelInfo(
      name: 'base',
      sizeBytes: 150 * 1024 * 1024, // ~150MB
      description: 'Fast with reasonable accuracy. Recommended for MVP.',
    ),
    WhisperModelInfo(
      name: 'small',
      sizeBytes: 500 * 1024 * 1024, // ~500MB
      description: 'Balanced speed and accuracy.',
    ),
    WhisperModelInfo(
      name: 'medium',
      sizeBytes: 1500 * 1024 * 1024, // ~1.5GB
      description: 'High accuracy, slower processing.',
    ),
    WhisperModelInfo(
      name: 'large',
      sizeBytes: 3000 * 1024 * 1024, // ~3GB
      description: 'Best accuracy, slowest processing.',
    ),
  ];

  /// Get model info by name.
  static WhisperModelInfo? getByName(String name) {
    try {
      return availableModels.firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }
}
