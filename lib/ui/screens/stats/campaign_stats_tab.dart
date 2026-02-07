import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../theme/spacing.dart';
import 'stat_widgets.dart';

/// Tab showing per-campaign statistics.
class CampaignStatsTab extends ConsumerWidget {
  const CampaignStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(campaignStatsListProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(child: Text('No campaigns yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: statsList.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, index) {
            final stats = statsList[index];
            return _CampaignStatCard(stats: stats);
          },
        );
      },
    );
  }
}

class _CampaignStatCard extends StatelessWidget {
  const _CampaignStatCard({required this.stats});

  final CampaignStats stats;

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
          Text(
            stats.campaignName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.sm,
            children: [
              InlineStat(label: 'Sessions', value: '${stats.totalSessions}'),
              InlineStat(
                label: 'Hours',
                value: stats.totalHoursPlayed.toStringAsFixed(1),
              ),
              InlineStat(label: 'Players', value: '${stats.playerCount}'),
              InlineStat(label: 'Entities', value: '${stats.totalEntities}'),
            ],
          ),
        ],
      ),
    );
  }
}
