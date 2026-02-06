import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'transcript_result.dart';
import 'transcription_service.dart';

/// Mock implementation of TranscriptionService for development/testing.
/// Generates realistic fake TTRPG transcript data without requiring whisper.cpp.
class MockTranscriptionService implements TranscriptionService {
  MockTranscriptionService({this.simulateDelay = true, this.delayFactor = 0.1});

  /// Whether to simulate processing delay.
  final bool simulateDelay;

  /// Delay factor: processing time = audio duration * factor.
  /// Default 0.1 means 10 seconds delay per 100 seconds of audio.
  final double delayFactor;

  bool _isTranscribing = false;
  bool _isCancelled = false;

  @override
  String get modelName => 'mock';

  @override
  int? get modelSizeBytes => 0;

  @override
  int? get preferredChunkDurationMs => null;

  @override
  bool get isTranscribing => _isTranscribing;

  @override
  Future<bool> isReady() async => true;

  @override
  Future<void> initialize() async {
    // No initialization needed for mock
  }

  @override
  Future<TranscriptResult> transcribe(
    String audioFilePath, {
    TranscriptionProgressCallback? onProgress,
    String language = 'en',
  }) async {
    _isTranscribing = true;
    _isCancelled = false;

    try {
      // Verify file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw const TranscriptionException(
          TranscriptionErrorType.fileNotFound,
          message: 'Audio file not found',
        );
      }

      // Get audio duration from file size (estimate for WAV)
      // WAV at 44.1kHz, 16-bit, mono = ~88KB per second
      final fileSize = await file.length();
      final estimatedDurationSec = (fileSize / 88000).round();
      final durationMs = estimatedDurationSec * 1000;

      // Report preparing phase
      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 0,
          totalChunks: 1,
          phase: TranscriptionPhase.preparing,
          message: 'Preparing mock transcription...',
        ),
      );

      // Simulate processing delay
      if (simulateDelay) {
        final delayMs = (estimatedDurationSec * delayFactor * 1000).round();
        final steps = 10;
        final stepDelay = delayMs ~/ steps;

        for (var i = 1; i <= steps; i++) {
          if (_isCancelled) {
            throw const TranscriptionException(
              TranscriptionErrorType.cancelled,
            );
          }

          await Future<void>.delayed(Duration(milliseconds: stepDelay));

          onProgress?.call(
            TranscriptionProgress(
              currentChunk: i,
              totalChunks: steps,
              phase: TranscriptionPhase.transcribing,
              message: 'Processing audio segment $i of $steps...',
            ),
          );
        }
      }

      if (_isCancelled) {
        throw const TranscriptionException(TranscriptionErrorType.cancelled);
      }

      // Generate mock transcript
      final result = _generateMockTranscript(durationMs);

      // Report complete
      onProgress?.call(
        const TranscriptionProgress(
          currentChunk: 1,
          totalChunks: 1,
          phase: TranscriptionPhase.complete,
          message: 'Transcription complete',
        ),
      );

      return result;
    } finally {
      _isTranscribing = false;
    }
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
  }

  @override
  Future<void> dispose() async {
    _isCancelled = true;
    _isTranscribing = false;
  }

  /// Generate a realistic mock TTRPG transcript.
  TranscriptResult _generateMockTranscript(int durationMs) {
    final random = Random();
    final segments = <TranscriptSegmentData>[];
    final textBuffer = StringBuffer();

    // Generate segments covering the duration
    var currentTimeMs = 0;
    var segmentIndex = 0;

    while (currentTimeMs < durationMs) {
      // Random segment duration: 3-15 seconds
      final segmentDuration = 3000 + random.nextInt(12000);
      final endTimeMs = min(currentTimeMs + segmentDuration, durationMs);

      // Get random dialogue line
      final text = _getRandomDialogue(random, segmentIndex);

      segments.add(
        TranscriptSegmentData(
          text: text,
          startTimeMs: currentTimeMs,
          endTimeMs: endTimeMs,
        ),
      );

      if (textBuffer.isNotEmpty) {
        textBuffer.write(' ');
      }
      textBuffer.write(text);

      currentTimeMs = endTimeMs;
      segmentIndex++;
    }

    return TranscriptResult(
      fullText: textBuffer.toString(),
      segments: segments,
      modelName: 'mock',
      language: 'en',
      processingTimeMs: (durationMs * delayFactor).round(),
    );
  }

  /// Get a random TTRPG-themed dialogue line.
  String _getRandomDialogue(Random random, int index) {
    // Mix of GM narration, player dialogue, and game mechanics
    final dialogues = _getMockDialogues();
    return dialogues[random.nextInt(dialogues.length)];
  }

  List<String> _getMockDialogues() {
    return const [
      // GM Narration
      'The tavern is dimly lit, with candles flickering on each table. '
          'You can hear the distant sound of a bard strumming a lute.',
      'As you approach the ancient door, you notice strange runes carved '
          'into the stone frame. They seem to pulse with a faint blue light.',
      'The goblin chieftain stands before you, his crude iron crown sitting '
          'askew on his head. He speaks in broken Common.',
      'You find yourselves at a crossroads. To the north, the path leads '
          'into a dark forest. To the east, you can see the spires of a city.',
      'The treasure chest opens to reveal a collection of gold coins, '
          'a silver dagger, and a rolled up piece of parchment.',

      // Player Actions
      'I want to investigate the runes. Can I make an Arcana check?',
      'Alright, I\'m going to sneak up behind the guard and try to '
          'pickpocket the keys from his belt.',
      'I cast Fireball centered on the group of orcs. That\'s 8d6 fire damage.',
      'Can I use my inspiration to reroll that saving throw?',
      'I\'d like to persuade the merchant to give us a better price. '
          'I rolled a 17 plus my charisma modifier of 3, so that\'s 20.',

      // Combat
      'That hits! Roll your damage.',
      'The skeleton swings its rusty sword at you but misses wide.',
      'You take 12 points of slashing damage as the blade connects.',
      'Initiative order: Theron goes first with a 22, then the dragon, '
          'then Mira, and finally the rest of the party.',
      'The healing word takes effect, and Kira regains 8 hit points.',

      // Roleplay Moments
      'My character turns to the innkeeper and asks about any strange '
          'occurrences in the village lately.',
      'Grimthor slams his fist on the table. We cannot let this injustice stand!',
      'I think we should rest before continuing. Everyone is low on spells.',
      'Does anyone have rope? We need to climb down this cliff.',
      'Remember when we first met in that dungeon? We\'ve come so far.',

      // World Building
      'The city of Whitehaven is known for its skilled blacksmiths and '
          'the magical academy that sits atop the hill.',
      'This is the Moonblade, an artifact from the Age of Dragons. '
          'It\'s said to grant its wielder power over shadows.',
      'Lord Vexmar rules this region with an iron fist. The peasants '
          'whisper of a resistance forming in the mountains.',
      'The Guild of Shadows has eyes everywhere. If they know we\'re here, '
          'we need to move quickly.',
      'According to the legend, the dragon Morvath sleeps beneath the '
          'mountain, guarding a hoard of legendary treasures.',

      // Game Mechanics
      'That\'s a natural 20! Critical hit!',
      'You need to make a Constitution saving throw against the poison.',
      'With your passive perception of 14, you notice something off.',
      'You\'re at advantage because you\'re flanking the enemy.',
      'Let me check my spell slots. I have two third-level slots remaining.',
    ];
  }
}
