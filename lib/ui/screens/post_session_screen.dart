import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/campaign_providers.dart';
import '../../providers/recording_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/transcription_providers.dart';
import '../theme/spacing.dart';
import '../widgets/info_card.dart';
import '../widgets/session_details_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/transcription_progress.dart';

/// Processing phase for the post-session screen.
enum _ProcessingPhase { savingAudio, transcribing, complete, error }

/// Post-session screen shown after recording completes.
/// Per APP_FLOW.md Flow 6: Post-Recording Processing.
class PostSessionScreen extends ConsumerStatefulWidget {
  const PostSessionScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<PostSessionScreen> createState() => _PostSessionScreenState();
}

class _PostSessionScreenState extends ConsumerState<PostSessionScreen> {
  _ProcessingPhase _phase = _ProcessingPhase.savingAudio;
  String? _errorMessage;
  Session? _session;
  int? _audioDurationSeconds;
  int? _audioFileSizeBytes;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processRecording());
  }

  Future<void> _processRecording() async {
    try {
      setState(() {
        _phase = _ProcessingPhase.savingAudio;
        _errorMessage = null;
      });

      final sessionRepo = ref.read(sessionRepositoryProvider);
      final recordingState = ref.read(recordingNotifierProvider);
      final audioService = ref.read(audioRecordingServiceProvider);

      final filePath = recordingState.filePath ?? audioService.currentFilePath;
      if (filePath == null) throw Exception('No recording file found');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found at: $filePath');
      }

      final fileSize = await file.length();
      final duration = recordingState.elapsedTime.inSeconds;

      await sessionRepo.createAudio(
        sessionId: widget.sessionId,
        filePath: filePath,
        fileSizeBytes: fileSize,
        format: 'wav',
        durationSeconds: duration,
      );

      final session = await sessionRepo.getSessionById(widget.sessionId);
      if (session != null) {
        await sessionRepo.updateSession(
          session.copyWith(durationSeconds: duration),
        );
        await sessionRepo.updateSessionStatus(
          widget.sessionId,
          SessionStatus.transcribing,
        );
      }

      final updatedSession = await sessionRepo.getSessionById(widget.sessionId);

      if (mounted) {
        setState(() {
          _session = updatedSession;
          _audioDurationSeconds = duration;
          _audioFileSizeBytes = fileSize;
          _audioFilePath = filePath;
          _phase = _ProcessingPhase.transcribing;
        });
        ref.read(sessionsRevisionProvider.notifier).state++;
        await _startTranscription(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _ProcessingPhase.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _startTranscription(String audioFilePath) async {
    try {
      final notifier = ref.read(transcriptionNotifierProvider.notifier);
      await notifier.transcribe(
        sessionId: widget.sessionId,
        audioFilePath: audioFilePath,
      );

      final state = ref.read(transcriptionNotifierProvider);
      if (state.hasError) {
        throw Exception(state.message ?? 'Transcription failed');
      }

      final sessionRepo = ref.read(sessionRepositoryProvider);
      final updatedSession = await sessionRepo.getSessionById(widget.sessionId);

      if (mounted) {
        setState(() {
          _session = updatedSession;
          _phase = _ProcessingPhase.complete;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _ProcessingPhase.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _retryProcessing() {
    ref.read(transcriptionNotifierProvider.notifier).reset();
    if (_audioFilePath != null && _phase == _ProcessingPhase.error) {
      setState(() {
        _phase = _ProcessingPhase.transcribing;
        _errorMessage = null;
      });
      _startTranscription(_audioFilePath!);
    } else {
      _processRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transcriptionState = ref.watch(transcriptionNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: _buildContent(theme, transcriptionState),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, TranscriptionState state) {
    switch (_phase) {
      case _ProcessingPhase.savingAudio:
        return const SavingStateIndicator();
      case _ProcessingPhase.transcribing:
        return TranscriptionProgressIndicator(
          progress: state.progress,
          message: state.message ?? 'Transcribing audio...',
          phase: state.phase,
          sessionDetailsWidget: _session != null
              ? SessionDetailsCard(
                  session: _session,
                  audioDurationSeconds: _audioDurationSeconds,
                  audioFileSizeBytes: _audioFileSizeBytes,
                )
              : null,
        );
      case _ProcessingPhase.complete:
        return _buildSuccessState(theme);
      case _ProcessingPhase.error:
        return _buildErrorState(theme);
    }
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: Spacing.lg),
        Text('Processing Failed', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(
          _errorMessage ?? 'An unexpected error occurred.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          'Your audio is saved and you can retry transcription later.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => context.go(
                Routes.sessionDetailPath(
                  widget.campaignId,
                  widget.sessionId,
                ),
              ),
              child: const Text('View Session'),
            ),
            const SizedBox(width: Spacing.md),
            FilledButton(
              onPressed: _retryProcessing,
              child: const Text('Retry Now'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: Icon(
            Icons.check,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text('Session Ready!', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        if (_session != null) StatusBadge(sessionStatus: _session!.status),
        const SizedBox(height: Spacing.xl),
        SessionDetailsCard(
          session: _session,
          audioDurationSeconds: _audioDurationSeconds,
          audioFileSizeBytes: _audioFileSizeBytes,
        ),
        const SizedBox(height: Spacing.lg),
        const InfoCard(
          icon: Icons.auto_awesome,
          message:
              'Your session has been transcribed and is queued for AI '
              'processing. You will be notified when summaries are ready.',
        ),
        const SizedBox(height: Spacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  context.go(Routes.campaignPath(widget.campaignId)),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Campaign Home'),
            ),
            const SizedBox(width: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.go(
                Routes.sessionDetailPath(widget.campaignId, widget.sessionId),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Session'),
            ),
          ],
        ),
      ],
    );
  }
}
