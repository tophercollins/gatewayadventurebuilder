import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/npc_relationship.dart';
import '../../../providers/world_providers.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';

/// Section displaying NPC relationships with player characters.
class NpcRelationshipsSection extends ConsumerWidget {
  const NpcRelationshipsSection({required this.relationshipsAsync, super.key});

  final AsyncValue<List<NpcRelationship>> relationshipsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationships',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        relationshipsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (relationships) {
            if (relationships.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.people_outline,
                message: 'No known relationships with player characters.',
              );
            }
            return Column(
              children: relationships.map((rel) {
                return _RelationshipCard(relationship: rel);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RelationshipCard extends ConsumerWidget {
  const _RelationshipCard({required this.relationship});

  final NpcRelationship relationship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final characterAsync = ref.watch(
      characterByIdProvider(relationship.characterId),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            _sentimentIcon(relationship.sentiment),
            color: _sentimentColor(theme, relationship.sentiment),
            size: Spacing.iconSize,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                characterAsync.when(
                  loading: () => const Text('Loading...'),
                  error: (e, _) => const Text('Unknown'),
                  data: (character) => Text(
                    character?.name ?? 'Unknown Character',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (relationship.relationship != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    relationship.relationship!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _sentimentColor(
                theme,
                relationship.sentiment,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Spacing.badgeRadius),
            ),
            child: Text(
              relationship.sentiment.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _sentimentColor(theme, relationship.sentiment),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _sentimentIcon(RelationshipSentiment sentiment) {
    switch (sentiment) {
      case RelationshipSentiment.friendly:
        return Icons.favorite_outline;
      case RelationshipSentiment.hostile:
        return Icons.dangerous_outlined;
      case RelationshipSentiment.neutral:
        return Icons.remove_circle_outline;
      case RelationshipSentiment.unknown:
        return Icons.help_outline;
    }
  }

  Color _sentimentColor(ThemeData theme, RelationshipSentiment sentiment) {
    switch (sentiment) {
      case RelationshipSentiment.friendly:
        return Colors.green;
      case RelationshipSentiment.hostile:
        return theme.colorScheme.error;
      case RelationshipSentiment.neutral:
        return theme.colorScheme.onSurfaceVariant;
      case RelationshipSentiment.unknown:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
