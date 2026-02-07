import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/world_providers.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';
import 'world_database_header.dart';
import 'world_entity_tabs.dart';

/// World Database screen showing world header and all entities.
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Column(
          children: [
            Flexible(
              flex: 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: WorldDatabaseHeader(world: data.world),
              ),
            ),
            if (data.totalEntities > 0)
              Expanded(
                child: WorldEntityTabs(
                  data: data,
                  campaignId: campaignId,
                  searchQuery: searchQuery,
                  onSearchChanged: onSearchChanged,
                ),
              )
            else
              const Expanded(
                child: EmptyState(
                  icon: Icons.public_outlined,
                  title: 'No entities yet',
                  message:
                      'NPCs, locations, items, monsters, and organisations '
                      'will appear here as they are discovered in your '
                      'sessions.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
