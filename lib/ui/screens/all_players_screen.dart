import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/global_providers.dart';
import '../../providers/image_providers.dart';
import '../../providers/player_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/image/image_storage_service.dart';
import '../theme/spacing.dart';
import '../widgets/entity_image.dart';
import '../widgets/image_picker_field.dart';

/// Global screen listing all players across all campaigns.
class AllPlayersScreen extends ConsumerWidget {
  const AllPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(allPlayersProvider);

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
      data: (players) => _PlayersContent(players: players),
    );
  }
}

class _PlayersContent extends ConsumerWidget {
  const _PlayersContent({required this.players});

  final List<PlayerSummary> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Stack(
          children: [
            players.isEmpty
                ? _EmptyState(
                    onCreatePlayer: () => _showPlayerDialog(context, ref),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Spacing.lg),
                    itemCount: players.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          child: Text(
                            'All Players',
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: _PlayerCard(summary: players[index - 1]),
                      );
                    },
                  ),
            if (players.isNotEmpty)
              Positioned(
                bottom: Spacing.lg,
                right: Spacing.lg,
                child: FloatingActionButton(
                  onPressed: () => _showPlayerDialog(context, ref),
                  tooltip: 'Add player',
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _PlayerFormDialog(ref: ref),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.summary});

  final PlayerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = summary.player;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () => context.push(Routes.playerDetailPath(player.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              EntityImage.avatar(
                imagePath: player.imagePath,
                fallbackIcon: Icons.person,
                size: 40,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      '${summary.campaignCount} '
                      'campaign${summary.campaignCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (player.notes != null && player.notes!.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        player.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePlayer});

  final VoidCallback onCreatePlayer;

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
              Icons.people_outline,
              size: Spacing.xxxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text('No players yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add players to track who plays in your campaigns',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              onPressed: onCreatePlayer,
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a new player.
class _PlayerFormDialog extends ConsumerStatefulWidget {
  const _PlayerFormDialog({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends ConsumerState<_PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String? _pendingImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final editor = widget.ref.read(playerEditorProvider);
      final playerId = await editor.createPlayerGlobal(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_pendingImagePath != null) {
        final imageService = ref.read(imageStorageProvider);
        final storedPath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'players',
          entityId: playerId,
          imageType: EntityImageType.avatar,
        );
        final playerRepo = ref.read(playerRepositoryProvider);
        final player = await playerRepo.getPlayerById(playerId);
        if (player != null) {
          await playerRepo.updatePlayer(player.copyWith(imagePath: storedPath));
          widget.ref.read(playersRevisionProvider.notifier).state++;
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add player: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Player'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImagePickerField(
                currentImagePath: null,
                pendingImagePath: _pendingImagePath,
                fallbackIcon: Icons.person,
                isBanner: false,
                onImageSelected: (path) =>
                    setState(() => _pendingImagePath = path),
                onImageRemoved: () => setState(() => _pendingImagePath = null),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  hintText: 'Enter player name',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Player name is required'
                    : null,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Spacing.fieldSpacing),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional notes about this player',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text('Failed to load players', style: theme.textTheme.titleLarge),
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
}
