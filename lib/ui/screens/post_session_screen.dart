import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/post_session_providers.dart';
import '../../providers/transcription_providers.dart';
import '../theme/spacing.dart';
import '../widgets/info_card.dart';
import '../widgets/session_details_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/transcription_progress.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postState = ref.watch(postSessionNotifierProvider);
    final transcriptionState = ref.watch(transcriptionNotifierProvider);

    // Trigger processing when the notifier is freshly created (idle).
    // processRecording transitions to savingAudio immediately,
    // so the idle guard prevents re-triggering on subsequent rebuilds.
    if (postState.phase == PostSessionPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(postSessionNotifierProvider.notifier).processRecording(
            widget.sessionId,
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: _buildContent(theme, postState, transcriptionState),
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    PostSessionState postState,
    TranscriptionState transcriptionState,
  ) {
    switch (postState.phase) {
      case PostSessionPhase.idle:
      case PostSessionPhase.savingAudio:
        return const SavingStateIndicator();
      case PostSessionPhase.transcribing:
        return TranscriptionProgressIndicator(
          progress: transcriptionState.progress,
          message: transcriptionState.message ?? 'Transcribing audio...',
          phase: transcriptionState.phase,
          sessionDetailsWidget: postState.session != null
              ? SessionDetailsCard(
                  session: postState.session,
                  audioDurationSeconds: postState.audioDurationSeconds,
                  audioFileSizeBytes: postState.audioFileSizeBytes,
                )
              : null,
        );
      case PostSessionPhase.complete:
        return _buildSuccessState(theme, postState);
      case PostSessionPhase.error:
        return _buildErrorState(theme, postState);
    }
  }

  Widget _buildErrorState(ThemeData theme, PostSessionState postState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: Spacing.lg),
        Text('Processing Failed', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(
          postState.error ?? 'An unexpected error occurred.',
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
              onPressed: () => ref
                  .read(postSessionNotifierProvider.notifier)
                  .retry(widget.sessionId),
              child: const Text('Retry Now'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme, PostSessionState postState) {
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
        if (postState.session != null)
          StatusBadge(sessionStatus: postState.session!.status),
        const SizedBox(height: Spacing.xl),
        SessionDetailsCard(
          session: postState.session,
          audioDurationSeconds: postState.audioDurationSeconds,
          audioFileSizeBytes: postState.audioFileSizeBytes,
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
