import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/editing_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

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
        if (resyncState.isResyncing) const _ResyncOverlay(),
      ],
    );
  }
}

class _ResyncOverlay extends StatelessWidget {
  const _ResyncOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: Spacing.md),
                Text('Resyncing content...'),
              ],
            ),
          ),
        ),
      ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _SessionHeader(
              detail: detail,
              onResync: () => _handleResync(context, ref),
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
              onViewMore: () =>
                  context.go(Routes.sessionEntitiesPath(campaignId, sessionId)),
              onEdit: () =>
                  context.go(Routes.sessionEntitiesPath(campaignId, sessionId)),
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
    // Get world ID from campaign
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
          sessionDetailProvider((campaignId: campaignId, sessionId: sessionId)),
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

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.detail, required this.onResync});

  final SessionDetailData detail;
  final VoidCallback onResync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = detail.session;

    // Check if any content has been edited
    final hasEdits =
        (detail.summary?.isEdited ?? false) ||
        detail.scenes.any((s) => s.isEdited) ||
        detail.npcs.any((n) => n.isEdited) ||
        detail.locations.any((l) => l.isEdited) ||
        detail.items.any((i) => i.isEdited) ||
        detail.actionItems.any((a) => a.isEdited) ||
        detail.playerMoments.any((m) => m.isEdited);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session.title ?? 'Session ${session.sessionNumber ?? '?'}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(sessionStatus: session.status),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              formatDate(session.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (session.durationSeconds != null) ...[
              const SizedBox(width: Spacing.md),
              Icon(
                Icons.schedule_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                formatDurationHuman(
                  Duration(seconds: session.durationSeconds!),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            if (hasEdits)
              OutlinedButton.icon(
                onPressed: onResync,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Resync'),
              ),
          ],
        ),
      ],
    );
  }
}
