import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player.dart';
import '../../data/models/player_moment.dart';
import '../../providers/editing_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../theme/spacing.dart';
import '../widgets/editable_moment_card.dart';
import '../widgets/empty_state.dart';

/// Player Moments drill-down screen.
/// Displays per-player breakdown with quotes, highlights, and memorable moments.
class SessionPlayersScreen extends ConsumerWidget {
  const SessionPlayersScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(
      sessionPlayerMomentsProvider(
        (campaignId: campaignId, sessionId: sessionId),
      ),
    );
    final editingState = ref.watch(playerMomentEditingProvider);

    return Stack(
      children: [
        momentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(error: error.toString()),
          data: (momentsByPlayer) => _PlayersContent(
            sessionId: sessionId,
            momentsByPlayer: momentsByPlayer,
          ),
        ),
        if (editingState.isLoading) const _LoadingOverlay(),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PlayersContent extends ConsumerStatefulWidget {
  const _PlayersContent({
    required this.sessionId,
    required this.momentsByPlayer,
  });

  final String sessionId;
  final Map<Player, List<PlayerMoment>> momentsByPlayer;

  @override
  ConsumerState<_PlayersContent> createState() => _PlayersContentState();
}

class _PlayersContentState extends ConsumerState<_PlayersContent> {
  late Map<Player, List<PlayerMoment>> _localMomentsByPlayer;

  @override
  void initState() {
    super.initState();
    _localMomentsByPlayer = _copyMap(widget.momentsByPlayer);
  }

  @override
  void didUpdateWidget(_PlayersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.momentsByPlayer != widget.momentsByPlayer) {
      _localMomentsByPlayer = _copyMap(widget.momentsByPlayer);
    }
  }

  Map<Player, List<PlayerMoment>> _copyMap(
    Map<Player, List<PlayerMoment>> source,
  ) {
    return {for (final e in source.entries) e.key: List.from(e.value)};
  }

  void _onMomentUpdated(Player player, PlayerMoment updated) {
    final moments = _localMomentsByPlayer[player];
    if (moments == null) return;

    final index = moments.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      setState(() {
        moments[index] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localMomentsByPlayer.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'No player moments',
        message:
            'Player highlights, quotes, and memorable moments will appear here once the session is processed.',
      );
    }

    // Sort players by name
    final sortedEntries = _localMomentsByPlayer.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: sortedEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              child: _PlayerSection(
                player: entry.key,
                moments: entry.value,
                onMomentUpdated: (m) => _onMomentUpdated(entry.key, m),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.player,
    required this.moments,
    required this.onMomentUpdated,
  });

  final Player player;
  final List<PlayerMoment> moments;
  final void Function(PlayerMoment updated) onMomentUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PlayerAvatar(name: player.name),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${moments.length} highlight${moments.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        ...moments.map(
          (moment) => Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: EditableMomentCard(
              moment: moment,
              onUpdate: onMomentUpdated,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
