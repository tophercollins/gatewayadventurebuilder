import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/world_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// World Database screen showing all entities across the campaign's world.
class WorldDatabaseScreen extends ConsumerStatefulWidget {
  const WorldDatabaseScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<WorldDatabaseScreen> createState() =>
      _WorldDatabaseScreenState();
}

class _WorldDatabaseScreenState extends ConsumerState<WorldDatabaseScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(worldDatabaseProvider(widget.campaignId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (data) {
        if (data == null) {
          return const NotFoundState(message: 'Campaign not found');
        }
        return _WorldDatabaseContent(
          data: data,
          campaignId: widget.campaignId,
          searchQuery: _searchQuery,
          onSearchChanged: (query) => setState(() => _searchQuery = query),
        );
      },
    );
  }
}

class _WorldDatabaseContent extends StatelessWidget {
  const _WorldDatabaseContent({
    required this.data,
    required this.campaignId,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final WorldDatabaseData data;
  final String campaignId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final hasContent = data.totalEntities > 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: hasContent
            ? DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    _SearchBar(
                      searchQuery: searchQuery,
                      onChanged: onSearchChanged,
                    ),
                    _EntityTabBar(
                      npcCount: data.npcs.length,
                      locationCount: data.locations.length,
                      itemCount: data.items.length,
                      monsterCount: data.monsters.length,
                      organisationCount: data.organisations.length,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _NpcsList(
                            npcs: data.npcs,
                            campaignId: campaignId,
                            searchQuery: searchQuery,
                          ),
                          _LocationsList(
                            locations: data.locations,
                            campaignId: campaignId,
                            searchQuery: searchQuery,
                          ),
                          _ItemsList(
                            items: data.items,
                            campaignId: campaignId,
                            searchQuery: searchQuery,
                          ),
                          _MonstersList(
                            monsters: data.monsters,
                            campaignId: campaignId,
                            searchQuery: searchQuery,
                          ),
                          _OrganisationsList(
                            organisations: data.organisations,
                            campaignId: campaignId,
                            searchQuery: searchQuery,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const EmptyState(
                icon: Icons.public_outlined,
                title: 'No entities yet',
                message:
                    'NPCs, locations, items, monsters, and organisations will appear here '
                    'as they are discovered in your sessions.',
              ),
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
          hintText: 'Search entities...',
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

class _EntityTabBar extends StatelessWidget {
  const _EntityTabBar({
    required this.npcCount,
    required this.locationCount,
    required this.itemCount,
    required this.monsterCount,
    required this.organisationCount,
  });

  final int npcCount;
  final int locationCount;
  final int itemCount;
  final int monsterCount;
  final int organisationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: TabBar(
        isScrollable: true,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'NPCs ($npcCount)'),
          Tab(text: 'Locations ($locationCount)'),
          Tab(text: 'Items ($itemCount)'),
          Tab(text: 'Monsters ($monsterCount)'),
          Tab(text: 'Orgs ($organisationCount)'),
        ],
      ),
    );
  }
}

class _NpcsList extends StatelessWidget {
  const _NpcsList({
    required this.npcs,
    required this.campaignId,
    required this.searchQuery,
  });

  final List<NpcWithCount> npcs;
  final String campaignId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterNpcs();
    if (filtered.isEmpty) {
      return EmptySectionState(
        icon: Icons.person_outline,
        message: searchQuery.isNotEmpty
            ? 'No NPCs match "$searchQuery"'
            : 'No NPCs in this world yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _WorldEntityCard(
            icon: Icons.person_outline,
            name: item.npc.name,
            subtitle: item.npc.role,
            description: item.npc.description,
            appearanceCount: item.appearanceCount,
            onTap: () =>
                context.push(Routes.npcDetailPath(campaignId, item.npc.id)),
          ),
        );
      },
    );
  }

  List<NpcWithCount> _filterNpcs() {
    if (searchQuery.isEmpty) return npcs;
    final query = searchQuery.toLowerCase();
    return npcs.where((item) {
      return item.npc.name.toLowerCase().contains(query) ||
          (item.npc.description?.toLowerCase().contains(query) ?? false) ||
          (item.npc.role?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class _LocationsList extends StatelessWidget {
  const _LocationsList({
    required this.locations,
    required this.campaignId,
    required this.searchQuery,
  });

  final List<LocationWithCount> locations;
  final String campaignId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterLocations();
    if (filtered.isEmpty) {
      return EmptySectionState(
        icon: Icons.place_outlined,
        message: searchQuery.isNotEmpty
            ? 'No locations match "$searchQuery"'
            : 'No locations in this world yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _WorldEntityCard(
            icon: Icons.place_outlined,
            name: item.location.name,
            subtitle: item.location.locationType,
            description: item.location.description,
            appearanceCount: item.appearanceCount,
            onTap: () => context.push(
              Routes.locationDetailPath(campaignId, item.location.id),
            ),
          ),
        );
      },
    );
  }

  List<LocationWithCount> _filterLocations() {
    if (searchQuery.isEmpty) return locations;
    final query = searchQuery.toLowerCase();
    return locations.where((item) {
      return item.location.name.toLowerCase().contains(query) ||
          (item.location.description?.toLowerCase().contains(query) ?? false) ||
          (item.location.locationType?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({
    required this.items,
    required this.campaignId,
    required this.searchQuery,
  });

  final List<ItemWithCount> items;
  final String campaignId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterItems();
    if (filtered.isEmpty) {
      return EmptySectionState(
        icon: Icons.inventory_2_outlined,
        message: searchQuery.isNotEmpty
            ? 'No items match "$searchQuery"'
            : 'No items in this world yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _WorldEntityCard(
            icon: Icons.inventory_2_outlined,
            name: item.item.name,
            subtitle: item.item.itemType,
            description: item.item.description,
            appearanceCount: item.appearanceCount,
            onTap: () =>
                context.push(Routes.itemDetailPath(campaignId, item.item.id)),
          ),
        );
      },
    );
  }

  List<ItemWithCount> _filterItems() {
    if (searchQuery.isEmpty) return items;
    final query = searchQuery.toLowerCase();
    return items.where((item) {
      return item.item.name.toLowerCase().contains(query) ||
          (item.item.description?.toLowerCase().contains(query) ?? false) ||
          (item.item.itemType?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class _MonstersList extends StatelessWidget {
  const _MonstersList({
    required this.monsters,
    required this.campaignId,
    required this.searchQuery,
  });

  final List<MonsterWithCount> monsters;
  final String campaignId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterMonsters();
    if (filtered.isEmpty) {
      return EmptySectionState(
        icon: Icons.pest_control_outlined,
        message: searchQuery.isNotEmpty
            ? 'No monsters match "$searchQuery"'
            : 'No monsters in this world yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _WorldEntityCard(
            icon: Icons.pest_control_outlined,
            name: item.monster.name,
            subtitle: item.monster.monsterType,
            description: item.monster.description,
            appearanceCount: item.appearanceCount,
            onTap: () => context.push(
              Routes.monsterDetailPath(campaignId, item.monster.id),
            ),
          ),
        );
      },
    );
  }

  List<MonsterWithCount> _filterMonsters() {
    if (searchQuery.isEmpty) return monsters;
    final query = searchQuery.toLowerCase();
    return monsters.where((item) {
      return item.monster.name.toLowerCase().contains(query) ||
          (item.monster.description?.toLowerCase().contains(query) ?? false) ||
          (item.monster.monsterType?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class _OrganisationsList extends StatelessWidget {
  const _OrganisationsList({
    required this.organisations,
    required this.campaignId,
    required this.searchQuery,
  });

  final List<OrganisationWithCount> organisations;
  final String campaignId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterOrganisations();
    if (filtered.isEmpty) {
      return EmptySectionState(
        icon: Icons.groups_outlined,
        message: searchQuery.isNotEmpty
            ? 'No organisations match "$searchQuery"'
            : 'No organisations in this world yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _WorldEntityCard(
            icon: Icons.groups_outlined,
            name: item.organisation.name,
            subtitle: item.organisation.organisationType,
            description: item.organisation.description,
            appearanceCount: item.appearanceCount,
            onTap: () => context.push(
              Routes.organisationDetailPath(
                campaignId,
                item.organisation.id,
              ),
            ),
          ),
        );
      },
    );
  }

  List<OrganisationWithCount> _filterOrganisations() {
    if (searchQuery.isEmpty) return organisations;
    final query = searchQuery.toLowerCase();
    return organisations.where((item) {
      return item.organisation.name.toLowerCase().contains(query) ||
          (item.organisation.description?.toLowerCase().contains(query) ??
              false) ||
          (item.organisation.organisationType?.toLowerCase().contains(query) ??
              false);
    }).toList();
  }
}

/// A card for displaying world entities with tap support and appearance count.
class _WorldEntityCard extends StatelessWidget {
  const _WorldEntityCard({
    required this.icon,
    required this.name,
    this.subtitle,
    this.description,
    required this.appearanceCount,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final String? subtitle;
  final String? description;
  final int appearanceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  icon,
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
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppearanceBadge(count: appearanceCount),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}

class _AppearanceBadge extends StatelessWidget {
  const _AppearanceBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Text(
        count == 1 ? '1 session' : '$count sessions',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
