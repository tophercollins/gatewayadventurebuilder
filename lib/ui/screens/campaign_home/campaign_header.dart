import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/models/campaign.dart';
import '../../../providers/campaign_providers.dart';
import '../../../providers/image_providers.dart';
import '../../../services/image/image_storage_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/entity_image.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/status_badge.dart';

class CampaignHeader extends ConsumerStatefulWidget {
  const CampaignHeader({required this.detail, super.key});

  final CampaignDetail detail;

  @override
  ConsumerState<CampaignHeader> createState() => _CampaignHeaderState();
}

class _CampaignHeaderState extends ConsumerState<CampaignHeader> {
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
    final campaign = widget.detail.campaign;
    _nameController = TextEditingController(text: campaign.name);
    _descriptionController = TextEditingController(
      text: campaign.description ?? '',
    );
    _syncGameSystem();
  }

  void _refreshEditFields() {
    final campaign = widget.detail.campaign;
    _nameController.text = campaign.name;
    _descriptionController.text = campaign.description ?? '';
    _pendingImagePath = null;
    _imageRemoved = false;
    _syncGameSystem();
  }

  void _syncGameSystem() {
    final system = widget.detail.campaign.gameSystem;
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

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final campaign = widget.detail.campaign;
      final imageService = ref.read(imageStorageProvider);
      final editor = ref.read(campaignEditorProvider);

      String? imagePath = campaign.imagePath;

      if (_imageRemoved && _pendingImagePath == null) {
        await imageService.deleteImage(
          entityType: 'campaigns',
          entityId: campaign.id,
        );
        imagePath = null;
      } else if (_pendingImagePath != null) {
        imagePath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'campaigns',
          entityId: campaign.id,
          imageType: EntityImageType.banner,
        );
      }

      final updated = campaign.copyWith(
        name: _nameController.text.trim(),
        gameSystem: _getGameSystem(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imagePath: imagePath,
        updatedAt: DateTime.now(),
      );
      await editor.updateCampaign(updated);
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update campaign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateStatus(CampaignStatus newStatus) async {
    if (newStatus == widget.detail.campaign.status) return;
    try {
      final updated = widget.detail.campaign.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await ref.read(campaignEditorProvider).updateCampaign(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _deleteCampaign() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Delete Campaign',
      message:
          'This will permanently delete this campaign and all its sessions. '
          'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(campaignEditorProvider)
          .deleteCampaign(widget.detail.campaign.id);
      if (mounted) context.go(Routes.campaigns);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete campaign: $e')),
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
    final campaign = widget.detail.campaign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (campaign.imagePath != null) ...[
          EntityImage.banner(
            imagePath: campaign.imagePath,
            fallbackIcon: Icons.auto_stories,
          ),
          const SizedBox(height: Spacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                campaign.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(status: campaign.status),
            const SizedBox(width: Spacing.xs),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _refreshEditFields();
                  setState(() => _isEditing = true);
                } else if (value == 'delete') {
                  _deleteCampaign();
                } else if (value.startsWith('status_')) {
                  final name = value.substring(7);
                  final newStatus = CampaignStatus.fromString(name);
                  _updateStatus(newStatus);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: Spacing.sm),
                      Text('Edit Campaign'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  enabled: false,
                  height: 32,
                  child: Text(
                    'Set Status',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final s in CampaignStatus.values)
                  PopupMenuItem(
                    value: 'status_${s.value}',
                    child: Row(
                      children: [
                        Icon(
                          campaign.status == s
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: campaign.status == s
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(s.value[0].toUpperCase() + s.value.substring(1)),
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
                        'Delete Campaign',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (campaign.gameSystem != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            campaign.gameSystem!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (campaign.description != null) ...[
          const SizedBox(height: Spacing.md),
          Text(campaign.description!, style: theme.textTheme.bodyLarge),
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
            'Edit Campaign',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ImagePickerField(
            currentImagePath: _imageRemoved
                ? null
                : widget.detail.campaign.imagePath,
            pendingImagePath: _pendingImagePath,
            fallbackIcon: Icons.auto_stories,
            isBanner: true,
            onImageSelected: (path) => setState(() => _pendingImagePath = path),
            onImageRemoved: () => setState(() {
              _pendingImagePath = null;
              _imageRemoved = true;
            }),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Campaign Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campaign name is required';
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
                onPressed: _isSaving ? null : _saveCampaign,
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
