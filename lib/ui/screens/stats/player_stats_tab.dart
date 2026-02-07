import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../theme/spacing.dart';
import 'stat_widgets.dart';

/// Tab showing per-player statistics across campaigns.
class PlayerStatsTab extends ConsumerWidget {
  const PlayerStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsListProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(child: Text('No players yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: statsList.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, index) {
            final stats = statsList[index];
            return _PlayerStatCard(stats: stats);
          },
        );
      },
    );
  }
}

class _PlayerStatCard extends StatelessWidget {
  const _PlayerStatCard({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancePct = (stats.attendanceRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.playerName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.sm,
            children: [
              InlineStat(label: 'Attendance', value: '$attendancePct%'),
              InlineStat(label: 'Sessions', value: '${stats.sessionsAttended}'),
              InlineStat(label: 'Campaigns', value: '${stats.campaignsPlayed}'),
              InlineStat(label: 'Moments', value: '${stats.momentsCount}'),
            ],
          ),
        ],
      ),
    );
  }
}
