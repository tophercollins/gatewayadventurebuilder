import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/character.dart';
import '../../providers/player_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// Characters list screen for a campaign, with search and status filtering.
class CharactersListScreen extends ConsumerStatefulWidget {
  const CharactersListScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<CharactersListScreen> createState() =>
      _CharactersListScreenState();
}

class _CharactersListScreenState extends ConsumerState<CharactersListScreen> {
  String _searchQuery = '';
  CharacterStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(
      campaignCharactersProvider(widget.campaignId),
    );
    final playersAsync = ref.watch(
      playersWithCharactersProvider(widget.campaignId),
    );

    return charactersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (characters) {
        // Build a player name lookup from the playersWithCharacters provider
        final playerNames = <String, String>{};
        playersAsync.whenData((list) {
          for (final pwc in list) {
            playerNames[pwc.player.id] = pwc.player.name;
          }
        });

        return _CharactersListContent(
          characters: characters,
          playerNames: playerNames,
          campaignId: widget.campaignId,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onStatusFilterChanged: (s) => setState(() => _statusFilter = s),
        );
      },
    );
  }
}

class _CharactersListContent extends StatelessWidget {
  const _CharactersListContent({
    required this.characters,
    required this.playerNames,
    required this.campaignId,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  final List<Character> characters;
  final Map<String, String> playerNames;
  final String campaignId;
  final String searchQuery;
  final CharacterStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CharacterStatus?> onStatusFilterChanged;

  List<Character> get _filteredCharacters {
    var filtered = characters;
    if (statusFilter != null) {
      filtered = filtered.where((c) => c.status == statusFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.race?.toLowerCase().contains(query) ?? false) ||
            (c.characterClass?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: Column(
            children: [
              _Header(campaignId: campaignId),
              const Expanded(
                child: EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No characters yet',
                  message: 'Add characters to this campaign to get started.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredCharacters;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Column(
          children: [
            _Header(campaignId: campaignId),
            _SearchBar(searchQuery: searchQuery, onChanged: onSearchChanged),
            _StatusFilterChips(
              selected: statusFilter,
              onChanged: onStatusFilterChanged,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptySectionState(
                      icon: Icons.person_search_outlined,
                      message: searchQuery.isNotEmpty
                          ? 'No characters match "$searchQuery"'
                          : 'No characters with this status.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(Spacing.lg),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final character = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.md),
                          child: _CharacterCard(
                            character: character,
                            playerName: playerNames[character.playerId],
                            onTap: () => context.push(
                              Routes.characterDetailPath(
                                campaignId,
                                character.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Characters', style: theme.textTheme.headlineSmall),
          ElevatedButton.icon(
            onPressed: () => context.go(Routes.newCharacterPath(campaignId)),
            icon: const Icon(Icons.add),
            label: const Text('Add Character'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.searchQuery, required this.onChanged});

  final String searchQuery;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search characters...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(''),
                )
              : null,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onChanged});

  final CharacterStatus? selected;
  final ValueChanged<CharacterStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: Spacing.sm),
          ...CharacterStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: _FilterChip(
                label: _formatStatus(status),
                isSelected: selected == status,
                onTap: () => onChanged(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(CharacterStatus status) {
    return switch (status) {
      CharacterStatus.active => 'Active',
      CharacterStatus.retired => 'Retired',
      CharacterStatus.dead => 'Dead',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    this.playerName,
    required this.onTap,
  });

  final Character character;
  final String? playerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _buildSubtitle();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                  size: Spacing.iconSize,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            character.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _StatusBadge(status: character.status),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    if (playerName != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        'Player: $playerName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: Spacing.iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (character.race != null) parts.add(character.race!);
    if (character.characterClass != null) parts.add(character.characterClass!);
    if (character.level != null) parts.add('Lv ${character.level}');
    return parts.join(' / ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      CharacterStatus.active => ('Active', theme.colorScheme.primary),
      CharacterStatus.retired => (
        'Retired',
        theme.colorScheme.onSurfaceVariant,
      ),
      CharacterStatus.dead => ('Dead', theme.colorScheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
