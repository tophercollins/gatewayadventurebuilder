import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/character.dart';
import '../../data/models/player.dart';
import '../../providers/player_providers.dart';
import '../theme/spacing.dart';
import '../widgets/player_card.dart';

/// Screen displaying all players and their characters in a campaign.
/// Provides buttons to add new players and characters.
class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersWithCharactersProvider(campaignId));

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorContent(error: error),
      data: (playersWithChars) => _PlayersContent(
        campaignId: campaignId,
        playersWithCharacters: playersWithChars,
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Spacing.xxl,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: Spacing.md),
            Text('Failed to load players', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersContent extends ConsumerWidget {
  const _PlayersContent({
    required this.campaignId,
    required this.playersWithCharacters,
  });

  final String campaignId;
  final List<PlayerWithCharacters> playersWithCharacters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: Spacing.lg),
              if (playersWithCharacters.isEmpty)
                _EmptyState(campaignId: campaignId)
              else
                _buildPlayersList(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Players & Characters', style: theme.textTheme.headlineSmall),
        Wrap(
          spacing: Spacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.newPlayerPath(campaignId)),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Player'),
            ),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.newCharacterPath(campaignId)),
              icon: const Icon(Icons.add),
              label: const Text('Add Character'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayersList(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playersWithCharacters.length,
      itemBuilder: (context, index) {
        final pwc = playersWithCharacters[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: PlayerCard(
            player: pwc.player,
            characters: pwc.characters,
            campaignId: campaignId,
            onPlayerUpdated: (player) => _updatePlayer(context, ref, player),
            onCharacterUpdated: (character) =>
                _updateCharacter(context, ref, character),
            onPlayerDeleted: () => _deletePlayer(context, ref, pwc.player),
            onCharacterDeleted: (characterId) =>
                _deleteCharacter(context, ref, characterId),
          ),
        );
      },
    );
  }

  Future<void> _updatePlayer(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    try {
      await ref.read(playerEditorProvider).updatePlayer(player, campaignId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update player: $e')));
      }
    }
  }

  Future<void> _updateCharacter(
    BuildContext context,
    WidgetRef ref,
    Character character,
  ) async {
    try {
      await ref
          .read(playerEditorProvider)
          .updateCharacter(character, campaignId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update character: $e')),
        );
      }
    }
  }

  Future<void> _deletePlayer(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    try {
      await ref.read(playerEditorProvider).deletePlayer(player, campaignId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete player: $e')));
      }
    }
  }

  Future<void> _deleteCharacter(
    BuildContext context,
    WidgetRef ref,
    String characterId,
  ) async {
    try {
      await ref
          .read(playerEditorProvider)
          .deleteCharacter(characterId, campaignId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete character: $e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: Spacing.xxxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text('No players yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add players and their characters to this campaign',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.newPlayerPath(campaignId)),
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Player'),
            ),
          ],
        ),
      ),
    );
  }
}
