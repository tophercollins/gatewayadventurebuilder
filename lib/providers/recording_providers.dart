import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio/audio_recording_service.dart';

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
  RecordingNotifier(this._audioService)
      : super(const RecordingScreenState());

  final AudioRecordingService _audioService;
  Timer? _timer;

  /// Initialize with session and campaign IDs.
  void initialize({
    required String sessionId,
    required String campaignId,
  }) {
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
      await _audioService.start(sessionId: state.sessionId!);
      state = state.copyWith(
        state: RecordingState.recording,
        clearError: true,
      );
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
      state = state.copyWith(
        state: RecordingState.stopped,
        filePath: filePath,
      );
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
class AttendeeSelectionState {
  const AttendeeSelectionState({
    this.selectedPlayerIds = const {},
    this.selectedCharacterIds = const {},
  });

  final Set<String> selectedPlayerIds;
  final Set<String> selectedCharacterIds;

  bool isPlayerSelected(String playerId) =>
      selectedPlayerIds.contains(playerId);

  bool isCharacterSelected(String characterId) =>
      selectedCharacterIds.contains(characterId);

  AttendeeSelectionState copyWith({
    Set<String>? selectedPlayerIds,
    Set<String>? selectedCharacterIds,
  }) {
    return AttendeeSelectionState(
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      selectedCharacterIds: selectedCharacterIds ?? this.selectedCharacterIds,
    );
  }
}

/// Notifier for managing attendee selection.
class AttendeeSelectionNotifier extends StateNotifier<AttendeeSelectionState> {
  AttendeeSelectionNotifier() : super(const AttendeeSelectionState());

  /// Toggle player selection (also selects/deselects their character).
  void togglePlayer(String playerId, String? characterId) {
    final newPlayerIds = Set<String>.from(state.selectedPlayerIds);
    final newCharacterIds = Set<String>.from(state.selectedCharacterIds);

    if (newPlayerIds.contains(playerId)) {
      newPlayerIds.remove(playerId);
      if (characterId != null) {
        newCharacterIds.remove(characterId);
      }
    } else {
      newPlayerIds.add(playerId);
      if (characterId != null) {
        newCharacterIds.add(characterId);
      }
    }

    state = state.copyWith(
      selectedPlayerIds: newPlayerIds,
      selectedCharacterIds: newCharacterIds,
    );
  }

  /// Select all players and their characters.
  void selectAll(List<(String playerId, String? characterId)> playerCharacters) {
    final playerIds = <String>{};
    final characterIds = <String>{};

    for (final (playerId, characterId) in playerCharacters) {
      playerIds.add(playerId);
      if (characterId != null) {
        characterIds.add(characterId);
      }
    }

    state = state.copyWith(
      selectedPlayerIds: playerIds,
      selectedCharacterIds: characterIds,
    );
  }

  /// Clear all selections.
  void clearAll() {
    state = const AttendeeSelectionState();
  }

  /// Get selected attendee data for creating session_attendees.
  List<({String playerId, String? characterId})> getSelectedAttendees() {
    return state.selectedPlayerIds.map((playerId) {
      // Find the character for this player if any selected
      String? characterId;
      for (final charId in state.selectedCharacterIds) {
        // Note: In the actual implementation, we'd need to look up
        // which character belongs to which player
        characterId = charId;
        break;
      }
      return (playerId: playerId, characterId: characterId);
    }).toList();
  }
}

/// Provider for attendee selection state.
final attendeeSelectionProvider =
    StateNotifierProvider<AttendeeSelectionNotifier, AttendeeSelectionState>(
  (ref) => AttendeeSelectionNotifier(),
);
