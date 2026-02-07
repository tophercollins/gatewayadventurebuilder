import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../../providers/player_providers.dart';
import '../../providers/recording_providers.dart';
import '../theme/spacing.dart';

/// Reusable attendee selection widget with player checkboxes
/// and character dropdowns. Used by SessionSetupScreen,
/// AddSessionScreen, and EditAttendeesDialog.
class AttendeeSelectionList extends ConsumerWidget {
  const AttendeeSelectionList({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersWithCharactersProvider(campaignId));
    final selection = ref.watch(attendeeSelectionProvider);

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (players) {
        if (players.isEmpty) {
          return const _EmptyPlayersState();
        }
        return _AttendeeList(players: players, selection: selection);
      },
    );
  }
}

class _EmptyPlayersState extends StatelessWidget {
  const _EmptyPlayersState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'No players in this campaign',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeList extends ConsumerWidget {
  const _AttendeeList({required this.players, required this.selection});

  final List<PlayerWithCharacters> players;
  final AttendeeSelectionState selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Select All / Clear header
        Row(
          children: [
            TextButton(
              onPressed: () => _selectAll(ref),
              child: const Text('Select All'),
            ),
            const SizedBox(width: Spacing.sm),
            TextButton(
              onPressed: () {
                ref.read(attendeeSelectionProvider.notifier).clearAll();
              },
              child: const Text('Clear'),
            ),
            const Spacer(),
            Text(
              '${selection.selectedCount} selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),

        // Player rows
        ...players.map(
          (pwc) => _PlayerRow(playerWithCharacters: pwc, selection: selection),
        ),
      ],
    );
  }

  void _selectAll(WidgetRef ref) {
    final playerCharacters = <(String, String?)>[];
    for (final pwc in players) {
      final activeChar = pwc.characters
          .where((c) => c.status == CharacterStatus.active)
          .firstOrNull;
      playerCharacters.add((pwc.player.id, activeChar?.id));
    }
    ref.read(attendeeSelectionProvider.notifier).selectAll(playerCharacters);
  }
}

class _PlayerRow extends ConsumerWidget {
  const _PlayerRow({
    required this.playerWithCharacters,
    required this.selection,
  });

  final PlayerWithCharacters playerWithCharacters;
  final AttendeeSelectionState selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final player = playerWithCharacters.player;
    final characters = playerWithCharacters.characters;
    final isSelected = selection.isPlayerSelected(player.id);
    final selectedCharId = selection.characterForPlayer(player.id);

    final activeChar = characters
        .where((c) => c.status == CharacterStatus.active)
        .firstOrNull;

    return InkWell(
      onTap: () {
        ref
            .read(attendeeSelectionProvider.notifier)
            .togglePlayer(player.id, activeChar?.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.listItemPaddingHorizontal,
          vertical: Spacing.listItemPaddingVertical,
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                ref
                    .read(attendeeSelectionProvider.notifier)
                    .togglePlayer(player.id, activeChar?.id);
              },
            ),
            const SizedBox(width: Spacing.sm),

            // Player avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Player name + character dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSelected && characters.isNotEmpty)
                    _CharacterDropdown(
                      characters: characters,
                      selectedCharacterId: selectedCharId,
                      playerId: player.id,
                    )
                  else if (isSelected && characters.isEmpty)
                    Text(
                      'No character',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (!isSelected && activeChar != null)
                    Text(
                      activeChar.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterDropdown extends ConsumerWidget {
  const _CharacterDropdown({
    required this.characters,
    required this.selectedCharacterId,
    required this.playerId,
  });

  final List<Character> characters;
  final String? selectedCharacterId;
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DropdownButton<String?>(
      value: selectedCharacterId,
      isExpanded: true,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'No character',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...characters.map(
          (c) => DropdownMenuItem<String?>(
            value: c.id,
            child: Row(
              children: [
                _StatusDot(status: c.status),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    _formatCharacterLabel(c),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (charId) {
        ref
            .read(attendeeSelectionProvider.notifier)
            .setCharacterForPlayer(playerId, charId);
      },
    );
  }

  String _formatCharacterLabel(Character c) {
    final parts = <String>[c.name];
    if (c.characterClass != null && c.characterClass!.isNotEmpty) {
      if (c.level != null) {
        parts.add('Lv${c.level} ${c.characterClass}');
      } else {
        parts.add(c.characterClass!);
      }
    }
    if (c.status != CharacterStatus.active) {
      parts.add('(${c.status.value})');
    }
    return parts.join(' - ');
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      CharacterStatus.active => theme.colorScheme.primary,
      CharacterStatus.retired => theme.colorScheme.outline,
      CharacterStatus.dead => theme.colorScheme.error,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
