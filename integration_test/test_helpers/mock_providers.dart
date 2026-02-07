import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ttrpg_tracker/data/models/notification_settings.dart';
import 'package:ttrpg_tracker/providers/notification_providers.dart';
import 'package:ttrpg_tracker/services/connectivity/connectivity_service.dart';
import 'package:ttrpg_tracker/providers/repository_providers.dart';

/// Mock connectivity service that always reports online.
/// Avoids platform channel issues from connectivity_plus in tests.
class MockConnectivityService extends ConnectivityService {
  MockConnectivityService() : super(connectivity: null);

  @override
  bool get isOnline => true;

  @override
  ConnectivityStatus get currentStatus => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get statusStream =>
      Stream.value(ConnectivityStatus.online);

  @override
  Future<void> initialize() async {}

  @override
  Future<ConnectivityStatus> checkConnectivity() async =>
      ConnectivityStatus.online;

  @override
  void dispose() {}
}

/// Creates a valid 16kHz mono 16-bit PCM WAV file at [path].
///
/// The header format matches WavResampler._createHeader() so
/// ensureWhisperFormat() returns the original path (no resampling).
Future<File> createDummyWavFile(String path, {int durationSeconds = 10}) async {
  const sampleRate = 16000;
  const numChannels = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample ~/ 8;
  final dataSize = durationSeconds * sampleRate * numChannels * bytesPerSample;
  final fileSize = 44 + dataSize; // 44-byte header + PCM data

  final buffer = ByteData(fileSize);
  var offset = 0;

  // RIFF header
  void writeString(String s) {
    for (var i = 0; i < s.length; i++) {
      buffer.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  void writeUint32(int value) {
    buffer.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  void writeUint16(int value) {
    buffer.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  writeString('RIFF');
  writeUint32(fileSize - 8); // ChunkSize
  writeString('WAVE');

  // fmt sub-chunk
  writeString('fmt ');
  writeUint32(16); // SubChunk1Size (PCM)
  writeUint16(1); // AudioFormat (PCM)
  writeUint16(numChannels);
  writeUint32(sampleRate);
  writeUint32(sampleRate * numChannels * bytesPerSample); // ByteRate
  writeUint16(numChannels * bytesPerSample); // BlockAlign
  writeUint16(bitsPerSample);

  // data sub-chunk
  writeString('data');
  writeUint32(dataSize);

  // PCM data: all zeros (silence)
  // offset is now 44; remaining bytes are already 0 in ByteData

  final file = File(path);
  await file.writeAsBytes(buffer.buffer.asUint8List());
  return file;
}

/// Notification settings notifier for tests.
/// Does NOT call FlutterSecureStorage (unavailable in test environment).
/// Settings are stored in memory only.
class TestNotificationSettingsNotifier
    extends StateNotifier<NotificationSettings>
    implements NotificationSettingsNotifier {
  TestNotificationSettingsNotifier() : super(const NotificationSettings());

  @override
  Future<void> setEmailEnabled(bool enabled) async {
    state = state.copyWith(emailEnabled: enabled);
  }

  @override
  Future<void> setEmailAddress(String? email) async {
    state = state.copyWith(emailAddress: email);
  }

  @override
  Future<void> setNotifyOnProcessingComplete(bool notify) async {
    state = state.copyWith(notifyOnProcessingComplete: notify);
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    state = settings;
  }
}

/// Seed data returned by [seedSessionData].
class SeedData {
  const SeedData({
    required this.campaignId,
    required this.worldId,
    required this.sessionId,
    required this.playerIds,
    required this.characterIds,
  });

  final String campaignId;
  final String worldId;
  final String sessionId;
  final List<String> playerIds;
  final List<String> characterIds;
}

/// Seeds the in-memory DB with a campaign, players, characters, session,
/// and attendees matching MockLLMService's player moment names.
///
/// Returns IDs for verification in tests.
Future<SeedData> seedSessionData(ProviderContainer container) async {
  final userRepo = container.read(userRepositoryProvider);
  final campaignRepo = container.read(campaignRepositoryProvider);
  final playerRepo = container.read(playerRepositoryProvider);
  final sessionRepo = container.read(sessionRepositoryProvider);

  // Create default user
  final user = await userRepo.getOrCreateDefaultUser();

  // Create campaign (auto-creates a world)
  final campaign = await campaignRepo.createCampaign(
    userId: user.id,
    name: 'Curse of Strahd',
    gameSystem: 'D&D 5e',
    description: 'A gothic horror campaign in the dread domain of Barovia.',
  );

  // Player names must match MockLLMService.extractPlayerMoments() output
  const playerNames = ['Alex', 'Sam', 'Jordan', 'Taylor'];
  const characterNames = [
    'Thorin Ironforge',
    'Elara Moonwhisper',
    'Zephyr',
    'Brother Marcus',
  ];

  final playerIds = <String>[];
  final characterIds = <String>[];

  for (var i = 0; i < playerNames.length; i++) {
    final player = await playerRepo.createPlayer(
      userId: user.id,
      name: playerNames[i],
    );
    playerIds.add(player.id);

    await playerRepo.addPlayerToCampaign(
      campaignId: campaign.id,
      playerId: player.id,
    );

    final character = await playerRepo.createCharacter(
      playerId: player.id,
      campaignId: campaign.id,
      name: characterNames[i],
    );
    characterIds.add(character.id);
  }

  // Create session
  final session = await sessionRepo.createSession(
    campaignId: campaign.id,
    sessionNumber: 1,
    title: 'Into the Mists',
    date: DateTime.now(),
  );

  // Set duration (createSession doesn't accept it directly)
  await sessionRepo.updateSession(session.copyWith(durationSeconds: 10));

  // Add attendees
  for (var i = 0; i < playerIds.length; i++) {
    await sessionRepo.addAttendee(
      sessionId: session.id,
      playerId: playerIds[i],
      characterId: characterIds[i],
    );
  }

  return SeedData(
    campaignId: campaign.id,
    worldId: campaign.worldId,
    sessionId: session.id,
    playerIds: playerIds,
    characterIds: characterIds,
  );
}
