import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/character.dart';
import '../../providers/campaign_providers.dart';
import '../../providers/global_providers.dart';
import '../theme/spacing.dart';
import '../widgets/entity_image.dart';

/// Global screen listing all characters across all campaigns.
class AllCharactersScreen extends ConsumerWidget {
  const AllCharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(allCharactersProvider);

    return charactersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
      data: (characters) => _CharactersContent(characters: characters),
    );
  }
}

class _CharactersContent extends ConsumerWidget {
  const _CharactersContent({required this.characters});

  final List<CharacterSummary> characters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Stack(
          children: [
            characters.isEmpty
                ? _EmptyState(
                    onCreateCharacter: () => _showCampaignPicker(context, ref),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Spacing.lg),
                    itemCount: characters.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          child: Text(
                            'All Characters',
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: _CharacterCard(summary: characters[index - 1]),
                      );
                    },
                  ),
            if (characters.isNotEmpty)
              Positioned(
                bottom: Spacing.lg,
                right: Spacing.lg,
                child: FloatingActionButton(
                  onPressed: () => _showCampaignPicker(context, ref),
                  tooltip: 'Add character',
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCampaignPicker(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CampaignPickerDialog(),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.summary});

  final CharacterSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = summary.character;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () => context.push(
          Routes.globalCharacterDetailPath(character.id),
        ),
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
              imagePath: character.imagePath,
              fallbackIcon: Icons.shield_outlined,
              size: 40,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    _subtitle(character),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    summary.campaignDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (character.status != CharacterStatus.active)
              Chip(
                label: Text(
                  character.status.value,
                  style: theme.textTheme.labelSmall,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
      ),
    );
  }

  String _subtitle(Character character) {
    final parts = <String>[];
    if (character.race != null) parts.add(character.race!);
    if (character.characterClass != null) parts.add(character.characterClass!);
    if (character.level != null) parts.add('Lvl ${character.level}');
    return parts.isEmpty ? 'Character' : parts.join(' · ');
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateCharacter});

  final VoidCallback onCreateCharacter;

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
              Icons.person_outline,
              size: Spacing.xxxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text('No characters yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add characters to your campaigns to track them here',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              onPressed: onCreateCharacter,
              icon: const Icon(Icons.add),
              label: const Text('Add Character'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog that lets the user pick a campaign, then navigates to add character.
class _CampaignPickerDialog extends ConsumerStatefulWidget {
  const _CampaignPickerDialog();

  @override
  ConsumerState<_CampaignPickerDialog> createState() =>
      _CampaignPickerDialogState();
}

class _CampaignPickerDialogState extends ConsumerState<_CampaignPickerDialog> {
  String? _selectedCampaignId;

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsListProvider);

    return AlertDialog(
      title: const Text('Add Character'),
      content: SizedBox(
        width: 400,
        child: campaignsAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Failed to load campaigns: $error'),
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return const Text(
                'You need to create a campaign first before adding characters.',
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Which campaign should this character belong to?'),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCampaignId,
                  decoration: const InputDecoration(
                    labelText: 'Campaign',
                    hintText: 'Select a campaign',
                  ),
                  items: campaigns.map((c) {
                    return DropdownMenuItem(
                      value: c.campaign.id,
                      child: Text(c.campaign.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCampaignId = v),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedCampaignId == null
              ? null
              : () {
                  Navigator.pop(context);
                  context.go(Routes.newCharacterPath(_selectedCampaignId!));
                },
          child: const Text('Continue'),
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
          Text('Failed to load characters', style: theme.textTheme.titleLarge),
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
