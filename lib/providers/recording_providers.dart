import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio/audio_recording_service.dart';
import '../services/audio/recording_recovery_service.dart';

/// Provider for the audio recording service (singleton).
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// State for the recording screen.
class RecordingScreenState {
  const RecordingScreenState({
    this.sessionId,
    this.campaignId,
    this.state = RecordingState.idle,
    this.elapsedTime = Duration.zero,
    this.error,
    this.filePath,
  });

  final String? sessionId;
  final String? campaignId;
  final RecordingState state;
  final Duration elapsedTime;
  final AudioRecordingException? error;
  final String? filePath;

  bool get isRecording => state == RecordingState.recording;
  bool get isPaused => state == RecordingState.paused;
  bool get hasError => error != null;

  RecordingScreenState copyWith({
    String? sessionId,
    String? campaignId,
    RecordingState? state,
    Duration? elapsedTime,
    AudioRecordingException? error,
    String? filePath,
    bool clearError = false,
  }) {
    return RecordingScreenState(
      sessionId: sessionId ?? this.sessionId,
      campaignId: campaignId ?? this.campaignId,
      state: state ?? this.state,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      error: clearError ? null : (error ?? this.error),
      filePath: filePath ?? this.filePath,
    );
  }
}

/// Notifier for managing recording state and timer.
class RecordingNotifier extends StateNotifier<RecordingScreenState> {
  RecordingNotifier(this._audioService) : super(const RecordingScreenState());

  final AudioRecordingService _audioService;
  Timer? _timer;

  /// Initialize with session and campaign IDs.
  void initialize({required String sessionId, required String campaignId}) {
    state = state.copyWith(
      sessionId: sessionId,
      campaignId: campaignId,
      clearError: true,
    );
  }

  /// Start recording.
  Future<void> startRecording() async {
    if (state.sessionId == null) return;

    try {
      await _audioService.start(
        sessionId: state.sessionId!,
        campaignId: state.campaignId,
      );
      state = state.copyWith(state: RecordingState.recording, clearError: true);
      _startTimer();
    } on AudioRecordingException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Stop recording and return the file path.
  Future<String?> stopRecording() async {
    _stopTimer();

    try {
      final filePath = await _audioService.stop();
      state = state.copyWith(state: RecordingState.stopped, filePath: filePath);
      return filePath;
    } on AudioRecordingException catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }

  /// Pause recording.
  Future<void> pauseRecording() async {
    try {
      await _audioService.pause();
      state = state.copyWith(state: RecordingState.paused);
    } on AudioRecordingException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Resume recording.
  Future<void> resumeRecording() async {
    try {
      await _audioService.resume();
      state = state.copyWith(state: RecordingState.recording);
    } on AudioRecordingException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Cancel recording.
  Future<void> cancelRecording() async {
    _stopTimer();

    try {
      await _audioService.cancel();
      state = state.copyWith(
        state: RecordingState.idle,
        elapsedTime: Duration.zero,
      );
    } on AudioRecordingException catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Clear any error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedTime: _audioService.elapsedTime);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Provider for the recording notifier.
final recordingNotifierProvider =
    StateNotifierProvider<RecordingNotifier, RecordingScreenState>((ref) {
      final audioService = ref.watch(audioRecordingServiceProvider);
      return RecordingNotifier(audioService);
    });

/// Provider for session attendee selection state.
/// Maps playerId → characterId (null = no character selected).
class AttendeeSelectionState {
  const AttendeeSelectionState({this.selections = const {}});

  /// Key = playerId, value = characterId (nullable).
  final Map<String, String?> selections;

  bool isPlayerSelected(String playerId) => selections.containsKey(playerId);

  String? characterForPlayer(String playerId) => selections[playerId];

  int get selectedCount => selections.length;

  AttendeeSelectionState copyWith({Map<String, String?>? selections}) {
    return AttendeeSelectionState(
      selections: selections ?? this.selections,
    );
  }
}

/// Notifier for managing attendee selection.
class AttendeeSelectionNotifier extends StateNotifier<AttendeeSelectionState> {
  AttendeeSelectionNotifier() : super(const AttendeeSelectionState());

  /// Toggle player selection. When adding, uses defaultCharacterId.
  void togglePlayer(String playerId, String? defaultCharacterId) {
    final updated = Map<String, String?>.from(state.selections);
    if (updated.containsKey(playerId)) {
      updated.remove(playerId);
    } else {
      updated[playerId] = defaultCharacterId;
    }
    state = state.copyWith(selections: updated);
  }

  /// Change the character selected for a player.
  void setCharacterForPlayer(String playerId, String? characterId) {
    if (!state.selections.containsKey(playerId)) return;
    final updated = Map<String, String?>.from(state.selections);
    updated[playerId] = characterId;
    state = state.copyWith(selections: updated);
  }

  /// Select all players with their default characters.
  void selectAll(
    List<(String playerId, String? characterId)> playerCharacters,
  ) {
    final updated = <String, String?>{};
    for (final (playerId, characterId) in playerCharacters) {
      updated[playerId] = characterId;
    }
    state = state.copyWith(selections: updated);
  }

  /// Clear all selections.
  void clearAll() {
    state = const AttendeeSelectionState();
  }

  /// Initialize from existing attendees (for edit mode).
  void initializeFrom(List<({String playerId, String? characterId})> attendees) {
    final updated = <String, String?>{};
    for (final a in attendees) {
      updated[a.playerId] = a.characterId;
    }
    state = state.copyWith(selections: updated);
  }

  /// Get selected attendee data for creating session_attendees.
  List<({String playerId, String? characterId})> getSelectedAttendees() {
    return state.selections.entries
        .map((e) => (playerId: e.key, characterId: e.value))
        .toList();
  }
}

/// Provider for attendee selection state.
final attendeeSelectionProvider =
    StateNotifierProvider<AttendeeSelectionNotifier, AttendeeSelectionState>(
      (ref) => AttendeeSelectionNotifier(),
    );

/// Provider for the recording recovery service.
final recordingRecoveryProvider = Provider<RecordingRecoveryService>((ref) {
  return RecordingRecoveryService();
});

/// Provider that checks for interrupted recordings on startup.
final interruptedRecordingProvider = FutureProvider<InterruptedRecording?>((
  ref,
) async {
  final recoveryService = ref.watch(recordingRecoveryProvider);
  return await recoveryService.checkForInterruptedRecording();
});
