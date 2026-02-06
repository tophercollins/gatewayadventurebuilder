import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/editing_providers.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../theme/spacing.dart';
import '../widgets/audio_player_card.dart';
import '../widgets/empty_state.dart';
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
            const SizedBox(height: Spacing.xl),
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

  Future<void> _handleResync(BuildContext context, WidgetRef ref) async {
    final campaignRepo = ref.read(campaignRepositoryProvider);
    final campaignWithWorld = await campaignRepo.getCampaignWithWorld(
      campaignId,
    );
    if (campaignWithWorld == null) {
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
      worldId: campaignWithWorld.world.id,
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
