import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item.dart';
import '../../data/models/location.dart';
import '../../data/models/monster.dart';
import '../../data/models/npc.dart';
import '../../providers/editing_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../theme/spacing.dart';
import '../widgets/editable_entity_card.dart';
import '../widgets/empty_state.dart';

/// Extracted Items drill-down screen.
/// Displays NPCs, locations, and items extracted from the session.
class SessionEntitiesScreen extends ConsumerWidget {
  const SessionEntitiesScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(
      sessionEntitiesProvider((campaignId: campaignId, sessionId: sessionId)),
    );
    final editingState = ref.watch(entityEditingProvider);

    return Stack(
      children: [
        entitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(error: error.toString()),
          data: (data) {
            if (data == null) {
              return const NotFoundState(message: 'Session not found');
            }
            return _EntitiesContent(
              campaignId: campaignId,
              sessionId: sessionId,
              npcs: data.npcs,
              locations: data.locations,
              items: data.items,
              monsters: data.monsters,
            );
          },
        ),
        if (editingState.isLoading) const _LoadingOverlay(),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _EntitiesContent extends StatelessWidget {
  const _EntitiesContent({
    required this.campaignId,
    required this.sessionId,
    required this.npcs,
    required this.locations,
    required this.items,
    required this.monsters,
  });

  final String campaignId;
  final String sessionId;
  final List<Npc> npcs;
  final List<Location> locations;
  final List<Item> items;
  final List<Monster> monsters;

  @override
  Widget build(BuildContext context) {
    final hasContent = npcs.isNotEmpty ||
        locations.isNotEmpty ||
        items.isNotEmpty ||
        monsters.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: hasContent
            ? DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    _EntityTabBar(
                      npcCount: npcs.length,
                      locationCount: locations.length,
                      itemCount: items.length,
                      monsterCount: monsters.length,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _NpcsList(
                            npcs: npcs,
                            campaignId: campaignId,
                            sessionId: sessionId,
                          ),
                          _LocationsList(
                            locations: locations,
                            campaignId: campaignId,
                            sessionId: sessionId,
                          ),
                          _ItemsList(
                            items: items,
                            campaignId: campaignId,
                            sessionId: sessionId,
                          ),
                          _MonstersList(
                            monsters: monsters,
                            campaignId: campaignId,
                            sessionId: sessionId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No entities extracted',
                message:
                    'NPCs, locations, items, and monsters will appear here once the session is processed.',
              ),
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
  });

  final int npcCount;
  final int locationCount;
  final int itemCount;
  final int monsterCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
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
        ],
      ),
    );
  }
}

class _NpcsList extends ConsumerStatefulWidget {
  const _NpcsList({
    required this.npcs,
    required this.campaignId,
    required this.sessionId,
  });

  final List<Npc> npcs;
  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<_NpcsList> createState() => _NpcsListState();
}

class _NpcsListState extends ConsumerState<_NpcsList> {
  late List<Npc> _localNpcs;

  @override
  void initState() {
    super.initState();
    _localNpcs = List.from(widget.npcs);
  }

  @override
  void didUpdateWidget(_NpcsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.npcs != widget.npcs) {
      _localNpcs = List.from(widget.npcs);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localNpcs.isEmpty) {
      return const EmptySectionState(
        icon: Icons.person_outline,
        message: 'No NPCs extracted from this session.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: _localNpcs.length,
      itemBuilder: (context, index) {
        final npc = _localNpcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: EditableEntityCard(
            icon: Icons.person_outline,
            name: npc.name,
            subtitle: npc.role,
            description: npc.description,
            isEdited: npc.isEdited,
            subtitleLabel: 'Role',
            onSave: ({required name, subtitle, description}) =>
                _onSaveNpc(index, npc, name, subtitle, description),
          ),
        );
      },
    );
  }

  Future<void> _onSaveNpc(
    int index,
    Npc original,
    String name,
    String? role,
    String? description,
  ) async {
    final notifier = ref.read(entityEditingProvider.notifier);
    final result = await notifier.updateNpc(
      original.id,
      name: name,
      role: role,
      description: description,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _localNpcs[index] = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NPC saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(entityEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _LocationsList extends ConsumerStatefulWidget {
  const _LocationsList({
    required this.locations,
    required this.campaignId,
    required this.sessionId,
  });

  final List<Location> locations;
  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<_LocationsList> createState() => _LocationsListState();
}

class _LocationsListState extends ConsumerState<_LocationsList> {
  late List<Location> _localLocations;

  @override
  void initState() {
    super.initState();
    _localLocations = List.from(widget.locations);
  }

  @override
  void didUpdateWidget(_LocationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _localLocations = List.from(widget.locations);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localLocations.isEmpty) {
      return const EmptySectionState(
        icon: Icons.place_outlined,
        message: 'No locations extracted from this session.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: _localLocations.length,
      itemBuilder: (context, index) {
        final location = _localLocations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: EditableEntityCard(
            icon: Icons.place_outlined,
            name: location.name,
            subtitle: location.locationType,
            description: location.description,
            isEdited: location.isEdited,
            subtitleLabel: 'Location Type',
            onSave: ({required name, subtitle, description}) =>
                _onSaveLocation(index, location, name, subtitle, description),
          ),
        );
      },
    );
  }

  Future<void> _onSaveLocation(
    int index,
    Location original,
    String name,
    String? locationType,
    String? description,
  ) async {
    final notifier = ref.read(entityEditingProvider.notifier);
    final result = await notifier.updateLocation(
      original.id,
      name: name,
      locationType: locationType,
      description: description,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _localLocations[index] = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(entityEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ItemsList extends ConsumerStatefulWidget {
  const _ItemsList({
    required this.items,
    required this.campaignId,
    required this.sessionId,
  });

  final List<Item> items;
  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<_ItemsList> createState() => _ItemsListState();
}

class _ItemsListState extends ConsumerState<_ItemsList> {
  late List<Item> _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_ItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _localItems = List.from(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localItems.isEmpty) {
      return const EmptySectionState(
        icon: Icons.inventory_2_outlined,
        message: 'No items extracted from this session.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: _localItems.length,
      itemBuilder: (context, index) {
        final item = _localItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: EditableEntityCard(
            icon: Icons.inventory_2_outlined,
            name: item.name,
            subtitle: item.itemType,
            description: item.description,
            isEdited: item.isEdited,
            subtitleLabel: 'Item Type',
            onSave: ({required name, subtitle, description}) =>
                _onSaveItem(index, item, name, subtitle, description),
          ),
        );
      },
    );
  }

  Future<void> _onSaveItem(
    int index,
    Item original,
    String name,
    String? itemType,
    String? description,
  ) async {
    final notifier = ref.read(entityEditingProvider.notifier);
    final result = await notifier.updateItem(
      original.id,
      name: name,
      itemType: itemType,
      description: description,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _localItems[index] = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(entityEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _MonstersList extends ConsumerStatefulWidget {
  const _MonstersList({
    required this.monsters,
    required this.campaignId,
    required this.sessionId,
  });

  final List<Monster> monsters;
  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<_MonstersList> createState() => _MonstersListState();
}

class _MonstersListState extends ConsumerState<_MonstersList> {
  late List<Monster> _localMonsters;

  @override
  void initState() {
    super.initState();
    _localMonsters = List.from(widget.monsters);
  }

  @override
  void didUpdateWidget(_MonstersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monsters != widget.monsters) {
      _localMonsters = List.from(widget.monsters);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localMonsters.isEmpty) {
      return const EmptySectionState(
        icon: Icons.pest_control_outlined,
        message: 'No monsters extracted from this session.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: _localMonsters.length,
      itemBuilder: (context, index) {
        final monster = _localMonsters[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: EditableEntityCard(
            icon: Icons.pest_control_outlined,
            name: monster.name,
            subtitle: monster.monsterType,
            description: monster.description,
            isEdited: monster.isEdited,
            subtitleLabel: 'Monster Type',
            onSave: ({required name, subtitle, description}) =>
                _onSaveMonster(index, monster, name, subtitle, description),
          ),
        );
      },
    );
  }

  Future<void> _onSaveMonster(
    int index,
    Monster original,
    String name,
    String? monsterType,
    String? description,
  ) async {
    final notifier = ref.read(entityEditingProvider.notifier);
    final result = await notifier.updateMonster(
      original.id,
      name: name,
      monsterType: monsterType,
      description: description,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _localMonsters[index] = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monster saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(entityEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
