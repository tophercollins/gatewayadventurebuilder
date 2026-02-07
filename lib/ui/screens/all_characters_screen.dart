import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/character.dart';
import '../../providers/global_providers.dart';
import '../theme/spacing.dart';

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

class _CharactersContent extends StatelessWidget {
  const _CharactersContent({required this.characters});

  final List<CharacterSummary> characters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: characters.isEmpty
            ? const _EmptyState()
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
      ),
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

    return GestureDetector(
      onTap: () => context.go(
        Routes.characterDetailPath(character.campaignId, character.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _statusColor(character.status, theme),
              child: Text(
                character.name.isNotEmpty
                    ? character.name[0].toUpperCase()
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
                    summary.campaignName,
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
    );
  }

  String _subtitle(Character character) {
    final parts = <String>[];
    if (character.race != null) parts.add(character.race!);
    if (character.characterClass != null) parts.add(character.characterClass!);
    if (character.level != null) parts.add('Lvl ${character.level}');
    return parts.isEmpty ? 'Character' : parts.join(' · ');
  }

  Color _statusColor(CharacterStatus status, ThemeData theme) {
    switch (status) {
      case CharacterStatus.active:
        return theme.colorScheme.primary;
      case CharacterStatus.retired:
        return theme.colorScheme.outline;
      case CharacterStatus.dead:
        return theme.colorScheme.error;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              'Characters can be added from within a campaign',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
          Text(
            'Failed to load characters',
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
}
