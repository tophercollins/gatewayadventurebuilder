import 'package:flutter/material.dart';

import '../../data/models/character.dart';
import '../../data/models/player.dart';
import '../theme/spacing.dart';
import 'character_detail_card.dart';
import 'player_edit_form.dart';

/// Card widget displaying a player with their characters.
/// Supports expandable view and inline editing.
class PlayerCard extends StatefulWidget {
  const PlayerCard({
    required this.player,
    required this.characters,
    required this.campaignId,
    required this.onPlayerUpdated,
    required this.onCharacterUpdated,
    super.key,
  });

  final Player player;
  final List<Character> characters;
  final String campaignId;
  final ValueChanged<Player> onPlayerUpdated;
  final ValueChanged<Character> onCharacterUpdated;

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  bool _isExpanded = false;
  bool _isEditingPlayer = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerHeader(theme),
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                widget.player.name.isNotEmpty
                    ? widget.player.name[0].toUpperCase()
                    : '?',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.player.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (widget.characters.isNotEmpty)
                    Text(
                      '${widget.characters.length} character${widget.characters.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerDetails(theme),
          if (widget.characters.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Characters',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.sm),
            ...widget.characters.map((character) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: CharacterDetailCard(
                  character: character,
                  onUpdated: widget.onCharacterUpdated,
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'No characters in this campaign',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerDetails(ThemeData theme) {
    if (_isEditingPlayer) {
      return PlayerEditForm(
        player: widget.player,
        onSave: (updatedPlayer) {
          widget.onPlayerUpdated(updatedPlayer);
          setState(() => _isEditingPlayer = false);
        },
        onCancel: () => setState(() => _isEditingPlayer = false),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player Details',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: Spacing.sm),
              if (widget.player.notes != null &&
                  widget.player.notes!.isNotEmpty) ...[
                Text(
                  'Notes:',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  widget.player.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ] else
                Text(
                  'No notes',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => setState(() => _isEditingPlayer = true),
          tooltip: 'Edit player',
        ),
      ],
    );
  }
}
