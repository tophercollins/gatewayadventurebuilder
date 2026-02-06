import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks active recordings and recovers from crashes.
class RecordingRecoveryService {
  static const _keyActiveSessionId = 'active_recording_session_id';
  static const _keyActiveCampaignId = 'active_recording_campaign_id';
  static const _keyActiveFilePath = 'active_recording_file_path';
  static const _keyActiveStartTime = 'active_recording_start_time';

  /// Mark a recording as active (call when recording starts).
  Future<void> markRecordingActive({
    required String sessionId,
    required String campaignId,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveSessionId, sessionId);
    await prefs.setString(_keyActiveCampaignId, campaignId);
    await prefs.setString(_keyActiveFilePath, filePath);
    await prefs.setString(
      _keyActiveStartTime,
      DateTime.now().toIso8601String(),
    );
  }

  /// Clear the active recording marker (call when recording stops normally).
  Future<void> clearActiveRecording() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveSessionId);
    await prefs.remove(_keyActiveCampaignId);
    await prefs.remove(_keyActiveFilePath);
    await prefs.remove(_keyActiveStartTime);
  }

  /// Check if there's an interrupted recording from a previous session.
  Future<InterruptedRecording?> checkForInterruptedRecording() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_keyActiveSessionId);
    final campaignId = prefs.getString(_keyActiveCampaignId);
    final filePath = prefs.getString(_keyActiveFilePath);
    final startTimeStr = prefs.getString(_keyActiveStartTime);

    if (sessionId == null || campaignId == null || filePath == null) {
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      await clearActiveRecording();
      return null;
    }

    final fileSize = await file.length();
    if (fileSize < 44) {
      await clearActiveRecording();
      return null;
    }

    final startTime =
        startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;

    return InterruptedRecording(
      sessionId: sessionId,
      campaignId: campaignId,
      filePath: filePath,
      fileSizeBytes: fileSize,
      startTime: startTime,
    );
  }
}

/// Data about an interrupted recording.
class InterruptedRecording {
  const InterruptedRecording({
    required this.sessionId,
    required this.campaignId,
    required this.filePath,
    required this.fileSizeBytes,
    this.startTime,
  });

  final String sessionId;
  final String campaignId;
  final String filePath;
  final int fileSizeBytes;
  final DateTime? startTime;

  /// Estimated duration based on file size (16kHz, 16-bit mono WAV).
  Duration get estimatedDuration {
    final audioBytes = fileSizeBytes - 44;
    if (audioBytes <= 0) return Duration.zero;
    final seconds = audioBytes / 32000;
    return Duration(seconds: seconds.round());
  }
}
