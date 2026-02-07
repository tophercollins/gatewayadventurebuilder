import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../theme/spacing.dart';
import 'stat_widgets.dart';

/// Tab showing per-world statistics.
class WorldStatsTab extends ConsumerWidget {
  const WorldStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(worldStatsListProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(child: Text('No worlds yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: statsList.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, index) {
            final stats = statsList[index];
            return _WorldStatCard(stats: stats);
          },
        );
      },
    );
  }
}

class _WorldStatCard extends StatelessWidget {
  const _WorldStatCard({required this.stats});

  final WorldStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stats.worldName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (stats.gameSystem != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Spacing.xs),
                  ),
                  child: Text(
                    stats.gameSystem!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.sm,
            children: [
              InlineStat(
                label: 'Campaigns',
                value: '${stats.campaignCount}',
              ),
              InlineStat(
                label: 'Sessions',
                value: '${stats.totalSessions}',
              ),
              InlineStat(label: 'Players', value: '${stats.totalPlayers}'),
              InlineStat(
                label: 'Characters',
                value: '${stats.totalCharacters}',
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.sm,
            children: [
              InlineStat(label: 'NPCs', value: '${stats.npcCount}'),
              InlineStat(
                label: 'Locations',
                value: '${stats.locationCount}',
              ),
              InlineStat(label: 'Items', value: '${stats.itemCount}'),
              InlineStat(label: 'Monsters', value: '${stats.monsterCount}'),
            ],
          ),
        ],
      ),
    );
  }
}
