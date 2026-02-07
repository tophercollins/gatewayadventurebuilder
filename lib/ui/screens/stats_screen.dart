import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/stats_providers.dart';
import '../theme/spacing.dart';

/// Stats dashboard showing campaign, player, and global statistics.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Campaigns'),
                  Tab(text: 'Players'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _GlobalStatsTab(),
                    _CampaignStatsTab(),
                    _PlayerStatsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStatsTab extends ConsumerWidget {
  const _GlobalStatsTab();

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
              _StatCard(
                label: 'Campaigns',
                value: '${stats.totalCampaigns}',
                icon: Icons.folder_outlined,
              ),
              _StatCard(
                label: 'Sessions',
                value: '${stats.totalSessions}',
                icon: Icons.book_outlined,
              ),
              _StatCard(
                label: 'Hours Played',
                value: stats.totalHoursRecorded.toStringAsFixed(1),
                icon: Icons.timer_outlined,
              ),
              _StatCard(
                label: 'NPCs',
                value: '${stats.totalNpcs}',
                icon: Icons.person_outlined,
              ),
              _StatCard(
                label: 'Locations',
                value: '${stats.totalLocations}',
                icon: Icons.place_outlined,
              ),
              _StatCard(
                label: 'Items',
                value: '${stats.totalItems}',
                icon: Icons.inventory_2_outlined,
              ),
              _StatCard(
                label: 'Monsters',
                value: '${stats.totalMonsters}',
                icon: Icons.pest_control_outlined,
              ),
              _StatCard(
                label: 'Longest Session',
                value: '${stats.longestSessionMinutes} min',
                icon: Icons.schedule_outlined,
              ),
              _StatCard(
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

class _CampaignStatsTab extends ConsumerWidget {
  const _CampaignStatsTab();

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
          separatorBuilder: (_, _) =>
              const SizedBox(height: Spacing.md),
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
              _InlineStat(
                label: 'Sessions',
                value: '${stats.totalSessions}',
              ),
              _InlineStat(
                label: 'Hours',
                value: stats.totalHoursPlayed.toStringAsFixed(1),
              ),
              _InlineStat(
                label: 'Players',
                value: '${stats.playerCount}',
              ),
              _InlineStat(
                label: 'Entities',
                value: '${stats.totalEntities}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerStatsTab extends ConsumerWidget {
  const _PlayerStatsTab();

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
          separatorBuilder: (_, _) =>
              const SizedBox(height: Spacing.md),
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
              _InlineStat(
                label: 'Attendance',
                value: '$attendancePct%',
              ),
              _InlineStat(
                label: 'Sessions',
                value: '${stats.sessionsAttended}',
              ),
              _InlineStat(
                label: 'Campaigns',
                value: '${stats.campaignsPlayed}',
              ),
              _InlineStat(
                label: 'Moments',
                value: '${stats.momentsCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: Spacing.iconSize,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
