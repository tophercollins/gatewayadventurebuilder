import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../data/models/campaign.dart';
import '../../../data/models/character.dart';
import '../../../data/models/player.dart';
import '../../../providers/player_providers.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';
import 'player_detail_widgets.dart';
import 'player_edit_form.dart';

/// Player detail screen showing info, campaigns, characters,
/// and edit/delete capabilities.
class PlayerDetailScreen extends ConsumerStatefulWidget {
  const PlayerDetailScreen({required this.playerId, super.key});

  final String playerId;

  @override
  ConsumerState<PlayerDetailScreen> createState() =>
      _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));
    final campaignsAsync = ref.watch(playerCampaignsProvider(widget.playerId));
    final charactersAsync = ref.watch(
      playerCharactersProvider(widget.playerId),
    );

    return playerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (player) {
        if (player == null) {
          return const NotFoundState(message: 'Player not found');
        }

        return _PlayerDetailContent(
          player: player,
          campaignsAsync: campaignsAsync,
          charactersAsync: charactersAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
          onDelete: _handleDelete,
        );
      },
    );
  }

  Future<void> _handleSave(Player updated) async {
    await ref.read(playerEditorProvider).updatePlayerGlobal(updated);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player updated')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: const Text(
          'Are you sure you want to delete this player? '
          'This will remove them from all campaigns. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(playerEditorProvider).deletePlayerGlobal(widget.playerId);
      if (mounted) {
        context.go(Routes.allPlayers);
      }
    }
  }
}

class _PlayerDetailContent extends StatelessWidget {
  const _PlayerDetailContent({
    required this.player,
    required this.campaignsAsync,
    required this.charactersAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
    required this.onDelete,
  });

  final Player player;
  final AsyncValue<List<Campaign>> campaignsAsync;
  final AsyncValue<List<Character>> charactersAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Player> onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerHeader(
                player: player,
                onEdit: onEditToggle,
                onDelete: onDelete,
              ),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                PlayerEditForm(
                  player: player,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                PlayerInfoSection(player: player),
                const SizedBox(height: Spacing.lg),
                _CampaignsSection(campaignsAsync: campaignsAsync),
                const SizedBox(height: Spacing.lg),
                _CharactersSection(charactersAsync: charactersAsync),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignsSection extends StatelessWidget {
  const _CampaignsSection({required this.campaignsAsync});

  final AsyncValue<List<Campaign>> campaignsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaigns',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        campaignsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.folder_outlined,
                message: 'Not linked to any campaigns.',
              );
            }
            return Column(
              children: campaigns
                  .map((c) => _CampaignTile(campaign: c))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(Routes.campaignPath(campaign.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  campaign.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharactersSection extends StatelessWidget {
  const _CharactersSection({required this.charactersAsync});

  final AsyncValue<List<Character>> charactersAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Characters',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        charactersAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (characters) {
            if (characters.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.shield_outlined,
                message: 'No characters yet.',
              );
            }
            return Column(
              children: characters
                  .map((c) => _CharacterTile(character: c))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          Routes.characterDetailPath(character.campaignId, character.id),
        ),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (character.characterClass != null)
                      Text(
                        character.characterClass!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
