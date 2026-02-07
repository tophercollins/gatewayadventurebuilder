import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_tracker/data/models/notification_settings.dart';
import 'package:ttrpg_tracker/data/models/session.dart';
import 'package:ttrpg_tracker/providers/notification_providers.dart';
import 'package:ttrpg_tracker/providers/processing_providers.dart';
import 'package:ttrpg_tracker/providers/queue_providers.dart';
import 'package:ttrpg_tracker/providers/repository_providers.dart';
import 'package:ttrpg_tracker/providers/transcription_providers.dart';
import 'package:ttrpg_tracker/services/notifications/email_service.dart';
import 'package:ttrpg_tracker/services/processing/mock_llm_service.dart';
import 'package:ttrpg_tracker/services/transcription/mock_transcription_service.dart';

import 'test_helpers/mock_providers.dart';
import 'test_helpers/test_app.dart';

void main() {
  late Database db;
  late ProviderContainer container;
  late String wavPath;
  late MockEmailService mockEmail;

  setUp(() async {
    db = await setUpTestEnvironment();

    mockEmail = MockEmailService();

    container = buildTestContainer(
      overrides: [
        transcriptionServiceProvider.overrideWithValue(
          MockTranscriptionService(simulateDelay: false),
        ),
        llmServiceProvider.overrideWithValue(
          MockLLMService(simulateDelay: false),
        ),
        emailServiceProvider.overrideWithValue(mockEmail),
        connectivityServiceProvider.overrideWithValue(
          MockConnectivityService(),
        ),
        // Override notification settings to avoid FlutterSecureStorage
        // issues in tests. The default NotificationSettingsNotifier tries
        // to load from secure storage asynchronously, which overwrites
        // any programmatically set settings.
        notificationSettingsProvider.overrideWith(
          (ref) => TestNotificationSettingsNotifier(),
        ),
      ],
    );

    wavPath = '${Directory.systemTemp.path}/test_session_audio.wav';
  });

  tearDown(() async {
    // Clean up temp WAV file
    final wavFile = File(wavPath);
    if (await wavFile.exists()) {
      await wavFile.delete();
    }
    container.dispose();
    await tearDownTestEnvironment(db);
  });

  test(
    'Full session pipeline: record → transcribe → AI → email',
    () async {
      // 1. Seed DB with campaign, players, characters, session, attendees
      final seed = await seedSessionData(container);

      // 2. Create dummy WAV file (10 seconds of silence)
      await createDummyWavFile(wavPath, durationSeconds: 10);

      // 3. Configure notification settings for email
      await container
          .read(notificationSettingsProvider.notifier)
          .updateSettings(
            const NotificationSettings(
              emailEnabled: true,
              emailAddress: 'gm@test.com',
              notifyOnProcessingComplete: true,
            ),
          );

      // 4. Save audio metadata to DB
      final sessionRepo = container.read(sessionRepositoryProvider);
      final wavFile = File(wavPath);
      final fileSize = await wavFile.length();
      await sessionRepo.createAudio(
        sessionId: seed.sessionId,
        filePath: wavPath,
        fileSizeBytes: fileSize,
        format: 'wav',
        durationSeconds: 10,
      );

      // 5. Set session status to transcribing
      await sessionRepo.updateSessionStatus(
        seed.sessionId,
        SessionStatus.transcribing,
      );

      // 6. Run transcription
      await container
          .read(transcriptionNotifierProvider.notifier)
          .transcribe(sessionId: seed.sessionId, audioFilePath: wavPath);

      // 7. Verify transcription completed
      final txState = container.read(transcriptionNotifierProvider);
      expect(
        txState.isComplete,
        isTrue,
        reason: 'Transcription should complete',
      );

      // 8. Verify transcript exists in DB
      final transcript = await sessionRepo.getLatestTranscript(seed.sessionId);
      expect(transcript, isNotNull, reason: 'Transcript should exist in DB');
      expect(
        transcript!.rawText,
        isNotEmpty,
        reason: 'Transcript text should not be empty',
      );

      // 9. Verify session status is queued (set by TranscriptionNotifier)
      final sessionAfterTx = await sessionRepo.getSessionById(seed.sessionId);
      expect(
        sessionAfterTx!.status,
        SessionStatus.queued,
        reason: 'Session should be queued for AI processing',
      );

      // 10. Verify notification settings are configured before processing
      final settingsBeforeProcessing = container.read(
        notificationSettingsProvider,
      );
      expect(
        settingsBeforeProcessing.isConfigured,
        isTrue,
        reason: 'Notification settings should be configured',
      );

      // Run AI processing
      final result = await container
          .read(processingStateProvider.notifier)
          .processSession(seed.sessionId);

      // 11. Verify processing succeeded
      expect(result.success, isTrue, reason: 'AI processing should succeed');
      expect(result.sceneCount, greaterThan(0));
      expect(result.npcCount, greaterThan(0));
      expect(result.locationCount, greaterThan(0));
      expect(result.itemCount, greaterThan(0));
      expect(result.actionItemCount, greaterThan(0));
      expect(result.momentCount, greaterThan(0));

      // 12. Verify session status is complete
      final sessionAfterAI = await sessionRepo.getSessionById(seed.sessionId);
      expect(
        sessionAfterAI!.status,
        SessionStatus.complete,
        reason: 'Session should be complete after AI processing',
      );

      // 13. Verify summary exists in DB
      final summaryRepo = container.read(summaryRepositoryProvider);
      final summary = await summaryRepo.getSummaryBySession(seed.sessionId);
      expect(summary, isNotNull, reason: 'Summary should exist in DB');
      expect(
        summary!.overallSummary,
        isNotEmpty,
        reason: 'Summary text should not be empty',
      );

      // 14. Verify entities were extracted
      final entityRepo = container.read(entityRepositoryProvider);
      final npcs = await entityRepo.getNpcsByWorld(seed.worldId);
      final locations = await entityRepo.getLocationsByWorld(seed.worldId);
      final items = await entityRepo.getItemsByWorld(seed.worldId);
      expect(npcs, isNotEmpty, reason: 'NPCs should be extracted');
      expect(locations, isNotEmpty, reason: 'Locations should be extracted');
      expect(items, isNotEmpty, reason: 'Items should be extracted');

      // 15. Verify email was sent
      expect(
        mockEmail.sentEmails.length,
        equals(1),
        reason: 'Exactly one email should be sent',
      );
      final email = mockEmail.sentEmails.first;
      expect(email.to, equals('gm@test.com'));
      expect(email.subject, contains('Curse of Strahd'));
      expect(email.htmlBody, contains('Curse of Strahd'));
      expect(email.htmlBody, contains('Duration'));
      expect(email.textBody, isNotNull);
      expect(email.textBody!, contains('Curse of Strahd'));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
