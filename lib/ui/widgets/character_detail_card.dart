import 'package:flutter/material.dart';

import '../../data/models/character.dart';
import '../theme/spacing.dart';
import 'character_edit_form.dart';

/// Card widget displaying character details with inline editing support.
class CharacterDetailCard extends StatefulWidget {
  const CharacterDetailCard({
    required this.character,
    required this.onUpdated,
    super.key,
  });

  final Character character;
  final ValueChanged<Character> onUpdated;

  @override
  State<CharacterDetailCard> createState() => _CharacterDetailCardState();
}

class _CharacterDetailCardState extends State<CharacterDetailCard> {
  bool _isExpanded = false;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = widget.character;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, character),
          if (_isExpanded) ...[
            Divider(height: 1, color: theme.colorScheme.outline),
            _buildExpandedContent(theme, character),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Character character) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Row(
          children: [
            _buildStatusBadge(theme, character.status),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (_hasSubtitle(character))
                    Text(
                      _buildSubtitle(character),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, CharacterStatus status) {
    final color = switch (status) {
      CharacterStatus.active => theme.colorScheme.primary,
      CharacterStatus.retired => theme.colorScheme.outline,
      CharacterStatus.dead => theme.colorScheme.error,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  bool _hasSubtitle(Character character) {
    return character.race != null ||
        character.characterClass != null ||
        character.level != null;
  }

  String _buildSubtitle(Character character) {
    final parts = <String>[];
    if (character.race != null) parts.add(character.race!);
    if (character.characterClass != null) parts.add(character.characterClass!);
    if (character.level != null) parts.add('Level ${character.level}');
    return parts.join(' - ');
  }

  Widget _buildExpandedContent(ThemeData theme, Character character) {
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: CharacterEditForm(
          character: character,
          onSave: (updatedCharacter) {
            widget.onUpdated(updatedCharacter);
            setState(() => _isEditing = false);
          },
          onCancel: () => setState(() => _isEditing = false),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Character Details',
                style: theme.textTheme.labelMedium,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: Spacing.iconSizeCompact),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit character',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: Spacing.buttonHeight,
                  minHeight: Spacing.buttonHeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _buildDetailRow(theme, 'Status', _formatStatus(character.status)),
          if (character.race != null)
            _buildDetailRow(theme, 'Race', character.race!),
          if (character.characterClass != null)
            _buildDetailRow(theme, 'Class', character.characterClass!),
          if (character.level != null)
            _buildDetailRow(theme, 'Level', character.level.toString()),
          if (character.backstory != null &&
              character.backstory!.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text('Backstory', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.xxs),
            Text(character.backstory!, style: theme.textTheme.bodySmall),
          ],
          if (character.goals != null && character.goals!.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text('Goals', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.xxs),
            Text(character.goals!, style: theme.textTheme.bodySmall),
          ],
          if (character.notes != null && character.notes!.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text('Notes', style: theme.textTheme.labelMedium),
            const SizedBox(height: Spacing.xxs),
            Text(character.notes!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
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
