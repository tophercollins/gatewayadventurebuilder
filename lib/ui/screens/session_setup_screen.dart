import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/character.dart';
import '../../providers/player_providers.dart';
import '../../providers/recording_providers.dart';
import '../../providers/repository_providers.dart';
import '../theme/spacing.dart';

/// Session setup screen for selecting attendees before recording.
/// Per APP_FLOW.md Flow 5: Start a Session (Recording).
class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({
    required this.campaignId,
    super.key,
  });

  final String campaignId;

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  bool _isStarting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Reset selection when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendeeSelectionProvider.notifier).clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(playersWithCharactersProvider(widget.campaignId));
    final selection = ref.watch(attendeeSelectionProvider);

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(theme, error.toString()),
            data: (players) => _buildContent(theme, players, selection),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    List<PlayerWithCharacters> players,
    AttendeeSelectionState selection,
  ) {
    if (players.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'Who is playing today?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Select the players and characters present for this session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Select All / Clear buttons
        Row(
          children: [
            TextButton(
              onPressed: () => _selectAll(players),
              child: const Text('Select All'),
            ),
            const SizedBox(width: Spacing.sm),
            TextButton(
              onPressed: () {
                ref.read(attendeeSelectionProvider.notifier).clearAll();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // Player list
        Expanded(
          child: ListView.separated(
            itemCount: players.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final playerWithChars = players[index];
              return _PlayerAttendeeItem(
                playerWithCharacters: playerWithChars,
                isSelected: selection.isPlayerSelected(playerWithChars.player.id),
                onToggle: () => _togglePlayer(playerWithChars),
              );
            },
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(Spacing.cardRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: Spacing.lg),

        // Start Recording button
        SizedBox(
          height: Spacing.buttonHeight,
          child: FilledButton.icon(
            onPressed: selection.selectedPlayerIds.isEmpty || _isStarting
                ? null
                : () => _startRecording(players),
            icon: _isStarting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.mic),
            label: Text(
              _isStarting ? 'Starting...' : 'Start Recording',
            ),
          ),
        ),

        const SizedBox(height: Spacing.sm),

        // Selected count
        Text(
          '${selection.selectedPlayerIds.length} player(s) selected',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No players yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Add players to your campaign before starting a session.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.tonal(
            onPressed: () {
              context.go(Routes.newPlayerPath(widget.campaignId));
            },
            child: const Text('Add Player'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Failed to load players',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _selectAll(List<PlayerWithCharacters> players) {
    final playerCharacters = <(String, String?)>[];
    for (final pwc in players) {
      // Use the first active character if available
      final activeChar = pwc.characters
          .where((c) => c.status == CharacterStatus.active)
          .firstOrNull;
      playerCharacters.add((pwc.player.id, activeChar?.id));
    }
    ref.read(attendeeSelectionProvider.notifier).selectAll(playerCharacters);
  }

  void _togglePlayer(PlayerWithCharacters playerWithChars) {
    // Use the first active character if available
    final activeChar = playerWithChars.characters
        .where((c) => c.status == CharacterStatus.active)
        .firstOrNull;
    ref.read(attendeeSelectionProvider.notifier).togglePlayer(
          playerWithChars.player.id,
          activeChar?.id,
        );
  }

  Future<void> _startRecording(List<PlayerWithCharacters> players) async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final selection = ref.read(attendeeSelectionProvider);

      // Get next session number
      final sessionNumber =
          await sessionRepo.getNextSessionNumber(widget.campaignId);

      // Create session with status 'recording'
      final session = await sessionRepo.createSession(
        campaignId: widget.campaignId,
        sessionNumber: sessionNumber,
        date: DateTime.now(),
      );

      // Create attendees for selected players
      for (final pwc in players) {
        if (selection.isPlayerSelected(pwc.player.id)) {
          // Find the selected character for this player
          final activeChar = pwc.characters
              .where((c) => c.status == CharacterStatus.active)
              .firstOrNull;

          await sessionRepo.addAttendee(
            sessionId: session.id,
            playerId: pwc.player.id,
            characterId: activeChar?.id,
          );
        }
      }

      // Navigate to recording screen
      if (mounted) {
        context.go(Routes.recordingPath(widget.campaignId, session.id));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start session: ${e.toString()}';
        _isStarting = false;
      });
    }
  }
}

/// Individual player/character selection item.
class _PlayerAttendeeItem extends StatelessWidget {
  const _PlayerAttendeeItem({
    required this.playerWithCharacters,
    required this.isSelected,
    required this.onToggle,
  });

  final PlayerWithCharacters playerWithCharacters;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = playerWithCharacters.player;
    final characters = playerWithCharacters.characters;
    final activeChar =
        characters.where((c) => c.status == CharacterStatus.active).firstOrNull;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.listItemPaddingHorizontal,
          vertical: Spacing.listItemPaddingVertical,
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
            ),
            const SizedBox(width: Spacing.sm),

            // Avatar
            CircleAvatar(
              backgroundColor: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Player and character info
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
                  if (activeChar != null) ...[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      _formatCharacterInfo(activeChar),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else if (characters.isEmpty) ...[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      'No character',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCharacterInfo(Character character) {
    final parts = <String>[character.name];

    if (character.characterClass != null && character.characterClass!.isNotEmpty) {
      if (character.level != null) {
        parts.add('Level ${character.level} ${character.characterClass}');
      } else {
        parts.add(character.characterClass!);
      }
    }

    return parts.join(' - ');
  }
}
