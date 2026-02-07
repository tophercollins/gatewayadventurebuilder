import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/location.dart';
import '../../data/models/session.dart';
import '../../utils/formatters.dart';
import '../../providers/world_providers.dart';
import '../theme/spacing.dart';
import '../../providers/image_providers.dart';
import '../../services/image/image_storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/entity_image.dart';
import '../widgets/image_picker_field.dart';

/// Location detail screen showing all location information and appearances.
class LocationDetailScreen extends ConsumerStatefulWidget {
  const LocationDetailScreen({
    required this.campaignId,
    required this.locationId,
    super.key,
  });

  final String campaignId;
  final String locationId;

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationByIdProvider(widget.locationId));
    final sessionsAsync = ref.watch(
      entitySessionsProvider((
        type: EntityType.location,
        entityId: widget.locationId,
      )),
    );

    return locationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (location) {
        if (location == null) {
          return const NotFoundState(message: 'Location not found');
        }
        return _LocationDetailContent(
          location: location,
          campaignId: widget.campaignId,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Location updatedLocation) async {
    await ref.read(entityEditorProvider).updateLocation(updatedLocation);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location updated')));
    }
  }
}

class _LocationDetailContent extends StatelessWidget {
  const _LocationDetailContent({
    required this.location,
    required this.campaignId,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Location location;
  final String campaignId;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Location> onSave;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationHeader(location: location, onEdit: onEditToggle),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                _LocationEditForm(
                  location: location,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                _LocationInfoSection(location: location),
                const SizedBox(height: Spacing.lg),
                _AppearancesSection(
                  sessionsAsync: sessionsAsync,
                  campaignId: campaignId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.location, required this.onEdit});

  final Location location;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        EntityImage.avatar(
          imagePath: location.imagePath,
          fallbackIcon: Icons.place_outlined,
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
                      location.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (location.isEdited)
                    Tooltip(
                      message: 'Manually edited',
                      child: Icon(
                        Icons.edit_note,
                        size: Spacing.iconSizeCompact,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              if (location.locationType != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  location.locationType!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
      ],
    );
  }
}

class _LocationInfoSection extends StatelessWidget {
  const _LocationInfoSection({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(location.description!, style: theme.textTheme.bodyMedium),
          ],
          if (location.notes != null) ...[
            if (location.description != null)
              const SizedBox(height: Spacing.md),
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(location.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (location.description == null && location.notes == null)
            Text(
              'No additional details available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _AppearancesSection extends StatelessWidget {
  const _AppearancesSection({
    required this.sessionsAsync,
    required this.campaignId,
  });

  final AsyncValue<List<Session>> sessionsAsync;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appeared In',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        sessionsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.history,
                message: 'No session appearances recorded.',
              );
            }
            return Column(
              children: sessions
                  .map(
                    (session) =>
                        _SessionCard(session: session, campaignId: campaignId),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.campaignId});

  final Session session;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push(Routes.sessionDetailPath(campaignId, session.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title ?? 'Session ${session.sessionNumber ?? ""}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      formatDate(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationEditForm extends ConsumerStatefulWidget {
  const _LocationEditForm({
    required this.location,
    required this.onSave,
    required this.onCancel,
  });

  final Location location;
  final ValueChanged<Location> onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<_LocationEditForm> createState() => _LocationEditFormState();
}

class _LocationEditFormState extends ConsumerState<_LocationEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _pendingImagePath;
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _typeController = TextEditingController(
      text: widget.location.locationType ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.location.description ?? '',
    );
    _notesController = TextEditingController(text: widget.location.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imagePath = widget.location.imagePath;
      final imageService = ref.read(imageStorageProvider);

      if (_imageRemoved && _pendingImagePath == null) {
        await imageService.deleteImage(
          entityType: 'locations',
          entityId: widget.location.id,
        );
        imagePath = null;
      } else if (_pendingImagePath != null) {
        imagePath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'locations',
          entityId: widget.location.id,
          imageType: EntityImageType.avatar,
        );
      }

      final updated = widget.location.copyWith(
        name: _nameController.text.trim(),
        locationType: _typeController.text.trim().isEmpty
            ? null
            : _typeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        imagePath: imagePath,
      );

      widget.onSave(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePickerField(
              currentImagePath: _imageRemoved
                  ? null
                  : widget.location.imagePath,
              pendingImagePath: _pendingImagePath,
              fallbackIcon: Icons.place_outlined,
              onImageSelected: (path) => setState(() {
                _pendingImagePath = path;
                _imageRemoved = false;
              }),
              onImageRemoved: () => setState(() {
                _pendingImagePath = null;
                _imageRemoved = true;
              }),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'e.g., city, dungeon, tavern',
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : widget.onCancel,
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
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
