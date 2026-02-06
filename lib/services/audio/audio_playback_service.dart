import 'dart:io';

import 'package:just_audio/just_audio.dart';

/// Service wrapping [AudioPlayer] from just_audio for session playback.
///
/// Exposes file loading, transport controls, speed adjustment, and
/// reactive streams for position/duration/player state.
class AudioPlaybackService {
  AudioPlaybackService();

  final AudioPlayer _player = AudioPlayer();

  /// Stream of the current playback position.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of the total duration (null until loaded).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of the player state (playing/processingState).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Whether audio is currently playing.
  bool get isPlaying => _player.playing;

  /// Current playback position.
  Duration get position => _player.position;

  /// Total duration of the loaded audio.
  Duration? get duration => _player.duration;

  /// Current playback speed.
  double get speed => _player.speed;

  /// Load an audio file from a local path.
  ///
  /// Converts to a file:// URI for cross-platform desktop compatibility
  /// with just_audio_media_kit.
  Future<Duration?> loadFile(String filePath) async {
    final uri = Uri.file(File(filePath).absolute.path);
    return _player.setAudioSource(AudioSource.uri(uri));
  }

  /// Start or resume playback.
  Future<void> play() => _player.play();

  /// Pause playback.
  Future<void> pause() => _player.pause();

  /// Seek to a specific position.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Set playback speed (e.g. 0.5, 1.0, 1.5, 2.0).
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Stop playback and reset position.
  Future<void> stop() => _player.stop();

  /// Release all resources.
  Future<void> dispose() => _player.dispose();
}
