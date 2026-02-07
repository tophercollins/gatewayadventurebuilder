import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/player.dart';
import '../../providers/player_providers.dart';
import '../theme/spacing.dart';
import 'entity_image.dart';

/// Dialog that lists existing players not yet in a campaign,
/// allowing single-tap linking. Includes a "Create New Player" option.
class LinkPlayerDialog extends ConsumerWidget {
  const LinkPlayerDialog({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(
      availablePlayersForCampaignProvider(campaignId),
    );

    return AlertDialog(
      title: const Text('Add Player'),
      content: SizedBox(
        width: 400,
        child: availableAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Failed to load players: $error'),
          data: (players) => _DialogContent(
            campaignId: campaignId,
            availablePlayers: players,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _DialogContent extends ConsumerStatefulWidget {
  const _DialogContent({
    required this.campaignId,
    required this.availablePlayers,
  });

  final String campaignId;
  final List<Player> availablePlayers;

  @override
  ConsumerState<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends ConsumerState<_DialogContent> {
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = widget.availablePlayers;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (players.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Text(
              'No additional players available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          Text(
            'Select an existing player to add:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: players.length,
              itemBuilder: (context, index) => _PlayerTile(
                player: players[index],
                enabled: !_isLinking,
                onTap: () => _linkPlayer(players[index]),
              ),
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        const Divider(),
        const SizedBox(height: Spacing.sm),
        OutlinedButton.icon(
          onPressed: _isLinking ? null : _createNewPlayer,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Create New Player'),
        ),
      ],
    );
  }

  Future<void> _linkPlayer(Player player) async {
    setState(() => _isLinking = true);
    try {
      await ref.read(playerEditorProvider).linkPlayerToCampaign(
        campaignId: widget.campaignId,
        playerId: player.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add player: $e')),
        );
        setState(() => _isLinking = false);
      }
    }
  }

  void _createNewPlayer() {
    Navigator.of(context).pop();
    context.go(Routes.newPlayerPath(widget.campaignId));
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.enabled,
    required this.onTap,
  });

  final Player player;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      leading: EntityImage.avatar(
        imagePath: player.imagePath,
        fallbackIcon: Icons.person,
        size: 40,
      ),
      title: Text(player.name),
      subtitle: player.notes != null && player.notes!.isNotEmpty
          ? Text(
              player.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Icon(
        Icons.add_circle_outline,
        color: enabled ? theme.colorScheme.primary : theme.disabledColor,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
