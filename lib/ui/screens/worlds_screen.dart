import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/campaign_providers.dart';
import '../../providers/global_providers.dart';
import '../../providers/image_providers.dart';
import '../../services/image/image_storage_service.dart';
import '../theme/spacing.dart';
import '../widgets/image_picker_field.dart';

/// Global screen listing all worlds with entity counts.
class WorldsScreen extends ConsumerWidget {
  const WorldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(allWorldsProvider);

    return worldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
      data: (worlds) => _WorldsContent(worlds: worlds),
    );
  }
}

class _WorldsContent extends ConsumerWidget {
  const _WorldsContent({required this.worlds});

  final List<WorldSummary> worlds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Stack(
          children: [
            worlds.isEmpty
                ? _EmptyState(
                    onCreateWorld: () => _showWorldDialog(context, ref),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Spacing.lg),
                    itemCount: worlds.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          child: Text(
                            'Worlds',
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: _WorldCard(summary: worlds[index - 1]),
                      );
                    },
                  ),
            if (worlds.isNotEmpty)
              Positioned(
                bottom: Spacing.lg,
                right: Spacing.lg,
                child: FloatingActionButton(
                  onPressed: () => _showWorldDialog(context, ref),
                  tooltip: 'Create world',
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWorldDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _WorldFormDialog(ref: ref),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.summary});

  final WorldSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final world = summary.world;
    final totalEntities =
        summary.npcCount + summary.locationCount + summary.itemCount;

    VoidCallback? onTap;
    if (summary.campaigns.isNotEmpty) {
      onTap = () =>
          context.push(Routes.worldDatabasePath(summary.campaigns.first.id));
    }

    final hasImage = world.imagePath != null && world.imagePath!.isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Spacing.cardRadius),
                    topRight: Radius.circular(Spacing.cardRadius),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 6,
                    child: Image.file(
                      File(world.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Spacing.cardPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (world.gameSystem != null) ...[
                            const SizedBox(height: Spacing.xxs),
                            Text(
                              world.gameSystem!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (world.description != null &&
                              world.description!.isNotEmpty) ...[
                            const SizedBox(height: Spacing.xxs),
                            Text(
                              world.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '$totalEntities entities  '
                            '${summary.campaigns.length} '
                            'campaign${summary.campaigns.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

/// Dialog for creating a new world.
class _WorldFormDialog extends ConsumerStatefulWidget {
  const _WorldFormDialog({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_WorldFormDialog> createState() => _WorldFormDialogState();
}

class _WorldFormDialogState extends ConsumerState<_WorldFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGameSystem;
  String? _customGameSystem;
  String? _pendingImagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getGameSystem() {
    if (_selectedGameSystem == 'Other') return _customGameSystem?.trim();
    return _selectedGameSystem;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final editor = widget.ref.read(worldEditorProvider);
      final imageService = ref.read(imageStorageProvider);

      final world = await editor.createWorld(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        gameSystem: _getGameSystem(),
      );

      if (_pendingImagePath != null) {
        final storedPath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'worlds',
          entityId: world.id,
          imageType: EntityImageType.avatar,
        );
        await editor.updateWorld(world.copyWith(imagePath: storedPath));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create world: $e'),
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
      title: const Text('New World'),
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
                fallbackIcon: Icons.public_outlined,
                isBanner: false,
                onImageSelected: (path) =>
                    setState(() => _pendingImagePath = path),
                onImageRemoved: () =>
                    setState(() => _pendingImagePath = null),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'World Name',
                  hintText: 'Enter world name',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'World name is required'
                    : null,
                autofocus: true,
              ),
              const SizedBox(height: Spacing.fieldSpacing),
              DropdownButtonFormField<String>(
                hint: const Text('Game system (optional)'),
                items: gameSystems
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedGameSystem = v;
                  if (v != 'Other') _customGameSystem = null;
                }),
                decoration: const InputDecoration(labelText: 'Game System'),
              ),
              if (_selectedGameSystem == 'Other') ...[
                const SizedBox(height: Spacing.fieldSpacing),
                TextFormField(
                  initialValue: _customGameSystem,
                  decoration: const InputDecoration(
                    labelText: 'Custom Game System',
                    hintText: 'Enter your game system',
                  ),
                  onChanged: (v) => _customGameSystem = v,
                  validator: (v) =>
                      _selectedGameSystem == 'Other' &&
                              (v == null || v.trim().isEmpty)
                          ? 'Please enter your game system'
                          : null,
                ),
              ],
              const SizedBox(height: Spacing.fieldSpacing),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of this world',
                ),
                maxLines: 3,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateWorld});

  final VoidCallback onCreateWorld;

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
              Icons.public_outlined,
              size: Spacing.xxxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: Spacing.md),
            Text('No worlds yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              'Create a world to share NPCs, locations, and items across campaigns',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              onPressed: onCreateWorld,
              icon: const Icon(Icons.add),
              label: const Text('Create World'),
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
          Text('Failed to load worlds', style: theme.textTheme.titleLarge),
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
