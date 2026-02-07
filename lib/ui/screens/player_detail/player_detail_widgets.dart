import 'package:flutter/material.dart';

import '../../../data/models/player.dart';
import '../../../utils/formatters.dart';
import '../../theme/spacing.dart';
import '../../widgets/entity_image.dart';

/// Header widget for player detail screen with avatar, name, and actions.
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    required this.player,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Player player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        EntityImage.avatar(
          imagePath: player.imagePath,
          fallbackIcon: Icons.person,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                'Joined ${formatDate(player.createdAt)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      ],
    );
  }
}

/// Info section showing player notes in a bordered card.
class PlayerInfoSection extends StatelessWidget {
  const PlayerInfoSection({required this.player, super.key});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (player.notes == null || player.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(player.notes!, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
