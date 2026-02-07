import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../theme/spacing.dart';
import 'stat_widgets.dart';

/// Tab showing per-character statistics.
class CharacterStatsTab extends ConsumerWidget {
  const CharacterStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(characterStatsListProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(child: Text('No characters yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: statsList.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, index) {
            final stats = statsList[index];
            return _CharacterStatCard(stats: stats);
          },
        );
      },
    );
  }
}

class _CharacterStatCard extends StatelessWidget {
  const _CharacterStatCard({required this.stats});

  final CharacterStats stats;

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
                  stats.characterName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(status: stats.status),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${stats.playerName} · ${stats.campaignDisplay}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.sm,
            children: [
              if (stats.characterClass != null)
                InlineStat(label: 'Class', value: stats.characterClass!),
              if (stats.race != null)
                InlineStat(label: 'Race', value: stats.race!),
              if (stats.level != null)
                InlineStat(label: 'Level', value: '${stats.level}'),
              InlineStat(label: 'Sessions', value: '${stats.sessionsAttended}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = switch (status) {
      'active' => (theme.colorScheme.primary, 'Active'),
      'retired' => (theme.colorScheme.outline, 'Retired'),
      'dead' => (theme.colorScheme.error, 'Dead'),
      _ => (theme.colorScheme.outline, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
