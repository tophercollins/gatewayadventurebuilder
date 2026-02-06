import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/player.dart';
import '../../providers/player_providers.dart';
import '../../providers/repository_providers.dart';
import '../theme/spacing.dart';

/// Screen for adding a new character to a campaign.
class AddCharacterScreen extends ConsumerStatefulWidget {
  const AddCharacterScreen({
    required this.campaignId,
    super.key,
  });

  final String campaignId;

  @override
  ConsumerState<AddCharacterScreen> createState() => _AddCharacterScreenState();
}

class _AddCharacterScreenState extends ConsumerState<AddCharacterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _raceController = TextEditingController();
  final _levelController = TextEditingController();
  final _backstoryController = TextEditingController();
  String? _selectedPlayerId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _raceController.dispose();
    _levelController.dispose();
    _backstoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a player'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final playerRepo = ref.read(playerRepositoryProvider);

      await playerRepo.createCharacter(
        playerId: _selectedPlayerId!,
        campaignId: widget.campaignId,
        name: _nameController.text.trim(),
        characterClass: _classController.text.trim().isEmpty
            ? null
            : _classController.text.trim(),
        race: _raceController.text.trim().isEmpty
            ? null
            : _raceController.text.trim(),
        level: _levelController.text.trim().isEmpty
            ? null
            : int.tryParse(_levelController.text.trim()),
        backstory: _backstoryController.text.trim().isEmpty
            ? null
            : _backstoryController.text.trim(),
      );

      // Invalidate providers to refresh the lists
      ref.invalidate(playersWithCharactersProvider(widget.campaignId));
      ref.invalidate(campaignCharactersProvider(widget.campaignId));

      if (mounted) {
        context.go(Routes.playersPath(widget.campaignId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add character: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(campaignPlayersProvider(widget.campaignId));

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(theme, error),
      data: (players) => _buildForm(theme, players),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
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
            Text(
              'Failed to load players',
              style: theme.textTheme.titleMedium,
            ),
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

  Widget _buildForm(ThemeData theme, List<Player> players) {
    final hasPlayers = players.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Character',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Create a character for one of the players in this campaign.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Spacing.xl),
                if (!hasPlayers) ...[
                  _buildNoPlayersMessage(theme),
                ] else ...[
                  _buildCharacterForm(theme, players),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPlayersMessage(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: Spacing.xxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No players in this campaign',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'You need to add at least one player before creating a character.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go(Routes.newPlayerPath(widget.campaignId)),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player First'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterForm(ThemeData theme, List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Spacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlayerId,
                  decoration: const InputDecoration(
                    labelText: 'Select Player',
                    hintText: 'Choose which player this character belongs to',
                  ),
                  items: players.map((player) {
                    return DropdownMenuItem(
                      value: player.id,
                      child: Text(player.name),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _selectedPlayerId = value);
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a player';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Character Details',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Spacing.md),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Character Name',
                    hintText: 'Enter the character\'s name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Character name is required';
                    }
                    return null;
                  },
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: Spacing.fieldSpacing),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _raceController,
                        decoration: const InputDecoration(
                          labelText: 'Race',
                          hintText: 'e.g., Elf, Dwarf, Human',
                        ),
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _classController,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          hintText: 'e.g., Fighter, Wizard',
                        ),
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.fieldSpacing),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _levelController,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final level = int.tryParse(value);
                        if (level == null || level < 1) {
                          return 'Invalid level';
                        }
                      }
                      return null;
                    },
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: Spacing.fieldSpacing),
                TextFormField(
                  controller: _backstoryController,
                  decoration: const InputDecoration(
                    labelText: 'Backstory',
                    hintText: 'Character background and history (optional)',
                  ),
                  maxLines: 5,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => context.go(Routes.playersPath(widget.campaignId)),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: Spacing.sm),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Character'),
            ),
          ],
        ),
      ],
    );
  }
}
