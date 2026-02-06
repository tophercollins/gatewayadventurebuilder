import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/editing_providers.dart';
import '../../providers/export_providers.dart';
import '../../providers/playback_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../../providers/transcription_providers.dart';
import '../theme/spacing.dart';
import '../widgets/audio_player_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/podcast_card.dart';
import '../widgets/section_card.dart';
import '../widgets/session_header.dart';

/// Session Detail screen - displays processed session with 4 sections.
/// Per APP_FLOW.md Flow 7: Summary, Extracted Items, What's Next, Player Moments.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      sessionDetailProvider((campaignId: campaignId, sessionId: sessionId)),
    );
    final resyncState = ref.watch(resyncProvider);

    return Stack(
      children: [
        detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(error: error.toString()),
          data: (detail) {
            if (detail == null) {
              return NotFoundState(
                message: 'Session not found',
                onBack: () => context.pop(),
              );
            }
            return _SessionDetailContent(
              detail: detail,
              campaignId: campaignId,
              sessionId: sessionId,
            );
          },
        ),
        if (resyncState.isResyncing) const ResyncOverlay(),
      ],
    );
  }
}

class _SessionDetailContent extends ConsumerWidget {
  const _SessionDetailContent({
    required this.detail,
    required this.campaignId,
    required this.sessionId,
  });

  final SessionDetailData detail;
  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioAsync = ref.watch(sessionAudioProvider(sessionId));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            SessionHeader(
              detail: detail,
              onResync: () => _handleResync(context, ref),
              onTitleUpdated: (newTitle) =>
                  _handleTitleUpdate(context, ref, newTitle),
            ),
            // Audio player card — shown only when audio exists for this session.
            ...audioAsync.when(
              loading: () => const <Widget>[],
              error: (_, _) => const <Widget>[],
              data: (audioInfo) {
                if (audioInfo == null) return const <Widget>[];
                return <Widget>[
                  const SizedBox(height: Spacing.md),
                  AudioPlayerCard(
                    sessionId: sessionId,
                    audioInfo: audioInfo,
                  ),
                ];
              },
            ),
            // Retry transcription banner for failed sessions
            if (detail.session.status == SessionStatus.error ||
                detail.session.status == SessionStatus.transcribing)
              ...audioAsync.when(
                loading: () => const <Widget>[],
                error: (_, _) => const <Widget>[],
                data: (audioInfo) {
                  if (audioInfo == null || !audioInfo.fileExists) {
                    return const <Widget>[];
                  }
                  return <Widget>[
                    const SizedBox(height: Spacing.md),
                    _RetryTranscriptionBanner(
                      sessionId: sessionId,
                      audioFilePath: audioInfo.filePath,
                      campaignId: campaignId,
                    ),
                  ];
                },
              ),
            const SizedBox(height: Spacing.xl),
            _TranscriptSectionCard(
              campaignId: campaignId,
              sessionId: sessionId,
            ),
            const SizedBox(height: Spacing.md),
            SectionCard(
              title: 'Session Summary',
              icon: Icons.description_outlined,
              preview: detail.summarySnippet,
              onViewMore: () =>
                  context.go(Routes.sessionSummaryPath(campaignId, sessionId)),
              onEdit: () =>
                  context.go(Routes.sessionSummaryPath(campaignId, sessionId)),
            ),
            const SizedBox(height: Spacing.md),
            PodcastCard(
              sessionId: sessionId,
              campaignId: campaignId,
            ),
            const SizedBox(height: Spacing.md),
            SectionCard(
              title: 'Extracted Items',
              icon: Icons.people_outline,
              preview: _buildEntitiesPreview(),
              onViewMore: () => context.go(
                Routes.sessionEntitiesPath(campaignId, sessionId),
              ),
              onEdit: () => context.go(
                Routes.sessionEntitiesPath(campaignId, sessionId),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SectionCard(
              title: "What's Next",
              icon: Icons.checklist_outlined,
              preview: detail.actionItemsSnippet,
              onViewMore: () =>
                  context.go(Routes.sessionActionsPath(campaignId, sessionId)),
              onEdit: () =>
                  context.go(Routes.sessionActionsPath(campaignId, sessionId)),
            ),
            const SizedBox(height: Spacing.md),
            SectionCard(
              title: 'Player Moments',
              icon: Icons.star_outline,
              preview: detail.playerMomentsSnippet,
              onViewMore: () =>
                  context.go(Routes.sessionPlayersPath(campaignId, sessionId)),
              onEdit: () =>
                  context.go(Routes.sessionPlayersPath(campaignId, sessionId)),
            ),
            const SizedBox(height: Spacing.xl),
            _ExportSection(
              sessionId: sessionId,
              campaignId: campaignId,
            ),
          ],
        ),
      ),
    );
  }

  String _buildEntitiesPreview() {
    final counts = <String>[];
    if (detail.npcs.isNotEmpty) {
      counts.add(
        '${detail.npcs.length} NPC${detail.npcs.length == 1 ? '' : 's'}',
      );
    }
    if (detail.locations.isNotEmpty) {
      counts.add(
        '${detail.locations.length} location${detail.locations.length == 1 ? '' : 's'}',
      );
    }
    if (detail.items.isNotEmpty) {
      counts.add(
        '${detail.items.length} item${detail.items.length == 1 ? '' : 's'}',
      );
    }
    if (counts.isEmpty) return 'No entities extracted';
    return counts.join(', ');
  }

  Future<void> _handleTitleUpdate(
    BuildContext context,
    WidgetRef ref,
    String newTitle,
  ) async {
    try {
      await ref.read(sessionEditorProvider).updateTitle(
        session: detail.session,
        newTitle: newTitle,
        campaignId: campaignId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update title: $e')),
        );
      }
    }
  }

  Future<void> _handleResync(BuildContext context, WidgetRef ref) async {
    final worldId = await ref.read(sessionEditorProvider).getWorldId(
      campaignId,
    );
    if (worldId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign not found')));
      }
      return;
    }

    final notifier = ref.read(resyncProvider.notifier);
    final result = await notifier.resyncSession(
      sessionId: sessionId,
      worldId: worldId,
    );

    if (!context.mounted) return;

    if (result.isSuccess) {
      if (result.totalUpdates > 0) {
        ref.invalidate(
          sessionDetailProvider(
            (campaignId: campaignId, sessionId: sessionId),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resync complete: ${result.totalUpdates} item(s) updated',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No updates needed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resync failed: ${result.error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Transcript section card that loads transcript data asynchronously.
class _TranscriptSectionCard extends ConsumerWidget {
  const _TranscriptSectionCard({
    required this.campaignId,
    required this.sessionId,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcriptAsync = ref.watch(sessionTranscriptProvider(sessionId));

    void navigateToTranscript() => context.go(
          Routes.sessionTranscriptPath(campaignId, sessionId),
        );

    return transcriptAsync.when(
      loading: () => SectionCard(
        title: 'Transcript',
        icon: Icons.text_snippet_outlined,
        preview: 'Loading...',
        onViewMore: navigateToTranscript,
        onEdit: navigateToTranscript,
      ),
      error: (_, _) => SectionCard(
        title: 'Transcript',
        icon: Icons.text_snippet_outlined,
        preview: 'Error loading transcript',
        onViewMore: navigateToTranscript,
        onEdit: navigateToTranscript,
      ),
      data: (transcript) {
        final preview = transcript != null
            ? _truncate(transcript.displayText, 150)
            : 'No transcript available';
        return SectionCard(
          title: 'Transcript',
          icon: Icons.text_snippet_outlined,
          preview: preview,
          onViewMore: navigateToTranscript,
          onEdit: navigateToTranscript,
        );
      },
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Banner shown on session detail when transcription failed or is pending.
/// Allows retrying transcription directly from the session detail screen.
class _RetryTranscriptionBanner extends ConsumerWidget {
  const _RetryTranscriptionBanner({
    required this.sessionId,
    required this.audioFilePath,
    required this.campaignId,
  });

  final String sessionId;
  final String audioFilePath;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transcriptionState = ref.watch(transcriptionNotifierProvider);
    final isTranscribing =
        transcriptionState.isActive &&
        transcriptionState.sessionId == sessionId;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isTranscribing
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(
          color: isTranscribing
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: isTranscribing
          ? _buildTranscribingState(theme, transcriptionState)
          : _buildRetryState(context, ref, theme),
    );
  }

  Widget _buildRetryState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            'Transcription failed. Audio is saved — you can retry.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        FilledButton(
          onPressed: () => _startTranscription(context, ref),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildTranscribingState(
    ThemeData theme,
    TranscriptionState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: state.progress > 0 ? state.progress : null,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                state.message ?? 'Transcribing...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        if (state.progress > 0) ...[
          const SizedBox(height: Spacing.xs),
          LinearProgressIndicator(value: state.progress),
        ],
      ],
    );
  }

  Future<void> _startTranscription(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(transcriptionNotifierProvider.notifier);
    await notifier.transcribe(
      sessionId: sessionId,
      audioFilePath: audioFilePath,
    );

    if (!context.mounted) return;

    final state = ref.read(transcriptionNotifierProvider);
    if (state.isComplete) {
      // Refresh session detail and transcript to show new data
      ref.invalidate(
        sessionDetailProvider(
          (campaignId: campaignId, sessionId: sessionId),
        ),
      );
      ref.invalidate(sessionTranscriptProvider(sessionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcription complete')),
      );
    }
  }
}

/// Export section with buttons for Markdown and JSON export.
class _ExportSection extends ConsumerWidget {
  const _ExportSection({
    required this.sessionId,
    required this.campaignId,
  });

  final String sessionId;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exportState = ref.watch(exportStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: exportState.isExporting
                  ? null
                  : () => _export(context, ref, 'markdown'),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Markdown'),
            ),
            const SizedBox(width: Spacing.sm),
            OutlinedButton.icon(
              onPressed: exportState.isExporting
                  ? null
                  : () => _export(context, ref, 'json'),
              icon: const Icon(Icons.data_object, size: 18),
              label: const Text('JSON'),
            ),
            if (exportState.isExporting) ...[
              const SizedBox(width: Spacing.sm),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        if (exportState.exportedFilePath != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              'Saved to: ${exportState.exportedFilePath}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (exportState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              exportState.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    await ref.read(exportStateProvider.notifier).exportSession(
      sessionId: sessionId,
      format: format,
    );

    if (!context.mounted) return;
    final result = ref.read(exportStateProvider);
    if (result.exportedFilePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${result.exportedFilePath}')),
      );
    }
  }
}
