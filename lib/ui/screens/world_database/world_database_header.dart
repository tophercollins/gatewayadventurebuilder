import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/models/world.dart';
import '../../../providers/campaign_providers.dart';
import '../../../providers/image_providers.dart';
import '../../../services/image/image_storage_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/entity_image.dart';
import '../../widgets/image_picker_field.dart';

class WorldDatabaseHeader extends ConsumerStatefulWidget {
  const WorldDatabaseHeader({required this.world, super.key});

  final World world;

  @override
  ConsumerState<WorldDatabaseHeader> createState() =>
      _WorldDatabaseHeaderState();
}

class _WorldDatabaseHeaderState extends ConsumerState<WorldDatabaseHeader> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedGameSystem;
  String? _customGameSystem;
  String? _pendingImagePath;
  bool _imageRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.world.name);
    _descriptionController = TextEditingController(
      text: widget.world.description ?? '',
    );
    _syncGameSystem();
  }

  void _refreshEditFields() {
    _nameController.text = widget.world.name;
    _descriptionController.text = widget.world.description ?? '';
    _pendingImagePath = null;
    _imageRemoved = false;
    _syncGameSystem();
  }

  void _syncGameSystem() {
    final system = widget.world.gameSystem;
    if (system != null && gameSystems.contains(system)) {
      _selectedGameSystem = system;
      _customGameSystem = null;
    } else if (system != null) {
      _selectedGameSystem = 'Other';
      _customGameSystem = system;
    } else {
      _selectedGameSystem = null;
      _customGameSystem = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getGameSystem() {
    if (_selectedGameSystem == 'Other') {
      return _customGameSystem?.trim();
    }
    return _selectedGameSystem;
  }

  Future<void> _saveWorld() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final world = widget.world;
      final imageService = ref.read(imageStorageProvider);
      final editor = ref.read(worldEditorProvider);

      String? imagePath = world.imagePath;

      if (_imageRemoved && _pendingImagePath == null) {
        await imageService.deleteImage(
          entityType: 'worlds',
          entityId: world.id,
        );
        imagePath = null;
      } else if (_pendingImagePath != null) {
        imagePath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'worlds',
          entityId: world.id,
          imageType: EntityImageType.banner,
        );
      }

      final updated = world.copyWith(
        name: _nameController.text.trim(),
        gameSystem: _getGameSystem(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imagePath: imagePath,
        updatedAt: DateTime.now(),
      );
      await editor.updateWorld(updated);
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update world: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteWorld() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Delete World',
      message:
          'This will permanently delete this world and all its entities '
          'and campaigns. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(worldEditorProvider).deleteWorld(widget.world.id);
      if (mounted) context.go(Routes.worlds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete world: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) return _buildEditForm(Theme.of(context));
    return _buildDisplay(Theme.of(context));
  }

  Widget _buildDisplay(ThemeData theme) {
    final world = widget.world;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (world.imagePath != null) ...[
          EntityImage.banner(
            imagePath: world.imagePath,
            fallbackIcon: Icons.public_outlined,
          ),
          const SizedBox(height: Spacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                world.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _refreshEditFields();
                  setState(() => _isEditing = true);
                } else if (value == 'delete') {
                  _deleteWorld();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: Spacing.sm),
                      Text('Edit World'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outlined,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Delete World',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (world.gameSystem != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            world.gameSystem!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (world.description != null &&
            world.description!.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Text(world.description!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit World',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ImagePickerField(
            currentImagePath: _imageRemoved
                ? null
                : widget.world.imagePath,
            pendingImagePath: _pendingImagePath,
            fallbackIcon: Icons.public_outlined,
            isBanner: true,
            onImageSelected: (path) =>
                setState(() => _pendingImagePath = path),
            onImageRemoved: () => setState(() {
              _pendingImagePath = null;
              _imageRemoved = true;
            }),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'World Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'World name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedGameSystem,
            hint: const Text('Select game system'),
            items: gameSystems.map((system) {
              return DropdownMenuItem(value: system, child: Text(system));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGameSystem = value;
                if (value != 'Other') _customGameSystem = null;
              });
            },
            decoration: const InputDecoration(labelText: 'Game System'),
          ),
          if (_selectedGameSystem == 'Other') ...[
            const SizedBox(height: Spacing.md),
            TextFormField(
              initialValue: _customGameSystem,
              decoration: const InputDecoration(
                labelText: 'Custom Game System',
              ),
              onChanged: (value) => _customGameSystem = value,
              validator: (value) {
                if (_selectedGameSystem == 'Other' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter your game system';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: _isSaving ? null : _saveWorld,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
