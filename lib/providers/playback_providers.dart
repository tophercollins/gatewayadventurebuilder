import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio/audio_playback_service.dart';
import 'repository_providers.dart';

/// Singleton provider for the audio playback service.
final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Playback status enum.
enum PlaybackStatus { idle, loading, playing, paused, completed, error }

/// Immutable state for the audio player UI.
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.sessionId,
    this.error,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? sessionId;
  final String? error;

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isLoaded =>
      status != PlaybackStatus.idle && status != PlaybackStatus.loading;

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? speed,
    String? sessionId,
    String? error,
    bool clearError = false,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      sessionId: sessionId ?? this.sessionId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier managing audio playback state, subscribing to service streams.
///
/// Uses autoDispose so stream subscriptions are cleaned up when no widget
/// is watching this provider, preventing defunct element errors.
class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(this._service) : super(const PlaybackState());

  final AudioPlaybackService _service;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Load audio for a session and start listening to streams.
  Future<void> loadSession(String filePath, String sessionId) async {
    // If already loaded for this session, just reset position.
    if (state.sessionId == sessionId && state.isLoaded) {
      await _service.seek(Duration.zero);
      state = state.copyWith(
        status: PlaybackStatus.paused,
        position: Duration.zero,
      );
      return;
    }

    _cancelSubscriptions();
    state = PlaybackState(
      status: PlaybackStatus.loading,
      sessionId: sessionId,
    );

    try {
      final duration = await _service.loadFile(filePath);
      if (!mounted) return;
      await _service.setSpeed(1.0);
      state = state.copyWith(
        status: PlaybackStatus.paused,
        duration: duration ?? Duration.zero,
        speed: 1.0,
      );
      _listenToStreams();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: PlaybackStatus.error,
        error: 'Failed to load audio: $e',
      );
    }
  }

  /// Toggle play/pause.
  Future<void> playPause() async {
    if (state.status == PlaybackStatus.completed) {
      await _service.seek(Duration.zero);
      await _service.play();
    } else if (_service.isPlaying) {
      await _service.pause();
    } else {
      await _service.play();
    }
  }

  /// Seek to a specific position.
  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  /// Set playback speed.
  Future<void> setSpeed(double speed) async {
    await _service.setSpeed(speed);
    if (mounted) state = state.copyWith(speed: speed);
  }

  /// Skip forward by the given duration.
  Future<void> skipForward(Duration amount) async {
    final target = state.position + amount;
    final clamped = target > state.duration ? state.duration : target;
    await _service.seek(clamped);
  }

  /// Skip backward by the given duration.
  Future<void> skipBackward(Duration amount) async {
    final target = state.position - amount;
    final clamped = target.isNegative ? Duration.zero : target;
    await _service.seek(clamped);
  }

  /// Stop playback and reset.
  Future<void> stopPlayback() async {
    _cancelSubscriptions();
    await _service.stop();
    if (mounted) state = const PlaybackState();
  }

  void _listenToStreams() {
    _subscriptions.add(
      _service.positionStream.listen((position) {
        if (mounted) {
          state = state.copyWith(position: position);
        }
      }),
    );

    _subscriptions.add(
      _service.durationStream.listen((duration) {
        if (mounted && duration != null) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    _subscriptions.add(
      _service.playerStateStream.listen((playerState) {
        if (!mounted) return;
        final processingState = playerState.processingState;
        if (processingState == ProcessingState.completed) {
          state = state.copyWith(status: PlaybackStatus.completed);
        } else if (playerState.playing) {
          state = state.copyWith(status: PlaybackStatus.playing);
        } else {
          state = state.copyWith(status: PlaybackStatus.paused);
        }
      }),
    );
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _service.stop();
    super.dispose();
  }
}

/// AutoDispose playback notifier — cleans up stream subscriptions when no
/// widget is watching, preventing defunct element assertions.
final playbackNotifierProvider = StateNotifierProvider.autoDispose<
    PlaybackNotifier, PlaybackState>((ref) {
  final service = ref.watch(audioPlaybackServiceProvider);
  return PlaybackNotifier(service);
});

/// Info about a session's audio file, including whether it exists on disk.
class SessionAudioInfo {
  const SessionAudioInfo({
    required this.filePath,
    required this.fileExists,
    this.durationSeconds,
  });

  final String filePath;
  final bool fileExists;
  final int? durationSeconds;
}

/// Loads session audio metadata and checks file existence.
final sessionAudioProvider =
    FutureProvider.autoDispose.family<SessionAudioInfo?, String>(
  (ref, sessionId) async {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final audio = await sessionRepo.getAudioBySession(sessionId);
    if (audio == null) return null;

    final exists = await File(audio.filePath).exists();
    return SessionAudioInfo(
      filePath: audio.filePath,
      fileExists: exists,
      durationSeconds: audio.durationSeconds,
    );
  },
);
