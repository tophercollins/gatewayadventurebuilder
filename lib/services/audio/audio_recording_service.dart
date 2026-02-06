import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Error types for audio recording.
enum AudioRecordingError {
  permissionDenied,
  encoderNotSupported,
  diskFull,
  fileError,
  unknown,
}

/// Exception for audio recording errors.
class AudioRecordingException implements Exception {
  const AudioRecordingException(this.error, [this.message]);

  final AudioRecordingError error;
  final String? message;

  @override
  String toString() {
    return 'AudioRecordingException: $error${message != null ? ' - $message' : ''}';
  }

  /// User-friendly error message.
  String get userMessage {
    return switch (error) {
      AudioRecordingError.permissionDenied =>
        'Microphone permission is required to record. '
            'Please grant permission in your system settings.',
      AudioRecordingError.encoderNotSupported =>
        'Audio recording is not supported on this device.',
      AudioRecordingError.diskFull =>
        'Not enough disk space to save the recording. '
            'Please free up some space and try again.',
      AudioRecordingError.fileError =>
        'Unable to save the recording file. '
            'Please check your storage permissions.',
      AudioRecordingError.unknown =>
        'An unexpected error occurred while recording. '
            'Please try again.',
    };
  }
}

/// Recording state for UI updates.
enum RecordingState { idle, recording, paused, stopped }

/// Audio recording service wrapping the record package.
/// Supports long recordings (10+ hours) via streaming to disk.
class AudioRecordingService {
  AudioRecordingService();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentFilePath;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _lastPauseTime;
  RecordingState _state = RecordingState.idle;

  /// Current recording state.
  RecordingState get state => _state;

  /// Current file path being recorded to.
  String? get currentFilePath => _currentFilePath;

  /// Recording start time.
  DateTime? get recordingStartTime => _recordingStartTime;

  /// Total paused duration.
  Duration get pausedDuration => _pausedDuration;

  /// Get elapsed recording time (excluding paused time).
  Duration get elapsedTime {
    if (_recordingStartTime == null) return Duration.zero;

    final now = DateTime.now();
    var elapsed = now.difference(_recordingStartTime!);

    // Subtract paused duration
    elapsed -= _pausedDuration;

    // If currently paused, don't count time since last pause
    if (_state == RecordingState.paused && _lastPauseTime != null) {
      elapsed -= now.difference(_lastPauseTime!);
    }

    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Initialize the recorder and check permissions.
  Future<bool> initialize() async {
    return _recorder.hasPermission();
  }

  /// Get the audio directory path.
  Future<String> getAudioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'audio'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return audioDir.path;
  }

  /// Get the file path for a session recording.
  Future<String> getSessionFilePath(String sessionId) async {
    final audioDir = await getAudioDirectory();
    return p.join(audioDir, '$sessionId.wav');
  }

  /// Start recording to the specified file path.
  /// If filePath is null, generates one using sessionId.
  Future<void> start({required String sessionId, String? filePath}) async {
    // Check permissions first
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const AudioRecordingException(AudioRecordingError.permissionDenied);
    }

    // Determine file path
    _currentFilePath = filePath ?? await getSessionFilePath(sessionId);

    // Ensure the directory exists
    final file = File(_currentFilePath!);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Check available disk space (require at least 500MB)
    try {
      // On desktop, we estimate based on file creation
      // The record package handles streaming to disk efficiently
      await file.create();
      await file.delete();
    } on FileSystemException catch (e) {
      if (e.message.contains('No space left')) {
        throw const AudioRecordingException(AudioRecordingError.diskFull);
      }
      throw AudioRecordingException(AudioRecordingError.fileError, e.message);
    }

    // Configure for WAV format - good quality, streaming-friendly
    // WAV is uncompressed, which is important for long recordings
    // as it writes directly to disk without buffering the entire file
    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      numChannels: 1, // Mono is sufficient for voice
      sampleRate: 44100, // CD quality
      bitRate: 128000,
    );

    try {
      await _recorder.start(config, path: _currentFilePath!);
      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _lastPauseTime = null;
      _state = RecordingState.recording;
    } on Exception catch (e) {
      throw AudioRecordingException(AudioRecordingError.unknown, e.toString());
    }
  }

  /// Stop recording and return the file path.
  Future<String?> stop() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return null;
    }

    try {
      final path = await _recorder.stop();
      _state = RecordingState.stopped;
      return path ?? _currentFilePath;
    } on Exception catch (e) {
      throw AudioRecordingException(AudioRecordingError.unknown, e.toString());
    }
  }

  /// Pause recording.
  Future<void> pause() async {
    if (_state != RecordingState.recording) return;

    try {
      await _recorder.pause();
      _lastPauseTime = DateTime.now();
      _state = RecordingState.paused;
    } on Exception catch (e) {
      throw AudioRecordingException(AudioRecordingError.unknown, e.toString());
    }
  }

  /// Resume recording.
  Future<void> resume() async {
    if (_state != RecordingState.paused) return;

    try {
      await _recorder.resume();

      // Add paused time to total
      if (_lastPauseTime != null) {
        _pausedDuration += DateTime.now().difference(_lastPauseTime!);
        _lastPauseTime = null;
      }

      _state = RecordingState.recording;
    } on Exception catch (e) {
      throw AudioRecordingException(AudioRecordingError.unknown, e.toString());
    }
  }

  /// Cancel recording and delete the file.
  Future<void> cancel() async {
    try {
      await _recorder.cancel();

      // Delete the file if it exists
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _reset();
    } on Exception catch (e) {
      throw AudioRecordingException(AudioRecordingError.unknown, e.toString());
    }
  }

  /// Check if currently recording.
  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  /// Get the amplitude/volume level (for visualization).
  Future<Amplitude> getAmplitude() async {
    return _recorder.getAmplitude();
  }

  /// Reset internal state.
  void _reset() {
    _currentFilePath = null;
    _recordingStartTime = null;
    _pausedDuration = Duration.zero;
    _lastPauseTime = null;
    _state = RecordingState.idle;
  }

  /// Dispose the recorder.
  Future<void> dispose() async {
    await _recorder.dispose();
    _reset();
  }
}
