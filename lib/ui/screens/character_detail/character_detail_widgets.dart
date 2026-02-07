import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/character.dart';
import '../../../data/models/player.dart';
import '../../theme/spacing.dart';
import '../../widgets/entity_image.dart';

/// Header widget for character detail screen with name, subtitle, and actions.
class CharacterHeader extends StatelessWidget {
  const CharacterHeader({
    required this.character,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Character character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _buildSubtitle();

    return Row(
      children: [
        EntityImage.avatar(
          imagePath: character.imagePath,
          fallbackIcon: Icons.shield_outlined,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
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

  String _buildSubtitle() {
    final parts = <String>[];
    if (character.race != null) parts.add(character.race!);
    if (character.characterClass != null) parts.add(character.characterClass!);
    if (character.level != null) parts.add('Lv ${character.level}');
    return parts.join(' / ');
  }
}

/// Info section showing character status, player, backstory, goals, and notes.
class CharacterInfoSection extends StatelessWidget {
  const CharacterInfoSection({
    required this.character,
    required this.playerAsync,
    super.key,
  });

  final Character character;
  final AsyncValue<Player?> playerAsync;

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
          _InfoRow(label: 'Status', value: _formatStatus(character.status)),
          playerAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (player) {
              if (player == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: Spacing.md),
                child: _InfoRow(label: 'Player', value: player.name),
              );
            },
          ),
          if (character.backstory != null) ...[
            const SizedBox(height: Spacing.md),
            _LongTextSection(label: 'Backstory', text: character.backstory!),
          ],
          if (character.goals != null) ...[
            const SizedBox(height: Spacing.md),
            _LongTextSection(label: 'Goals', text: character.goals!),
          ],
          if (character.notes != null) ...[
            const SizedBox(height: Spacing.md),
            _LongTextSection(label: 'Notes', text: character.notes!),
          ],
        ],
      ),
    );
  }

  String _formatStatus(CharacterStatus status) {
    return switch (status) {
      CharacterStatus.active => 'Active',
      CharacterStatus.retired => 'Retired',
      CharacterStatus.dead => 'Dead',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _LongTextSection extends StatelessWidget {
  const _LongTextSection({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
