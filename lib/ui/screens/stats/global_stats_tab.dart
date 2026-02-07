import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../theme/spacing.dart';
import 'stat_widgets.dart';

/// Overview tab showing aggregate stats across all data.
class GlobalStatsTab extends ConsumerWidget {
  const GlobalStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(globalStatsProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              StatCard(
                label: 'Campaigns',
                value: '${stats.totalCampaigns}',
                icon: Icons.folder_outlined,
              ),
              StatCard(
                label: 'Sessions',
                value: '${stats.totalSessions}',
                icon: Icons.book_outlined,
              ),
              StatCard(
                label: 'Hours Played',
                value: stats.totalHoursRecorded.toStringAsFixed(1),
                icon: Icons.timer_outlined,
              ),
              StatCard(
                label: 'NPCs',
                value: '${stats.totalNpcs}',
                icon: Icons.person_outlined,
              ),
              StatCard(
                label: 'Locations',
                value: '${stats.totalLocations}',
                icon: Icons.place_outlined,
              ),
              StatCard(
                label: 'Items',
                value: '${stats.totalItems}',
                icon: Icons.inventory_2_outlined,
              ),
              StatCard(
                label: 'Monsters',
                value: '${stats.totalMonsters}',
                icon: Icons.pest_control_outlined,
              ),
              StatCard(
                label: 'Longest Session',
                value: '${stats.longestSessionMinutes} min',
                icon: Icons.schedule_outlined,
              ),
              StatCard(
                label: 'Total Entities',
                value: '${stats.totalEntities}',
                icon: Icons.public_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
