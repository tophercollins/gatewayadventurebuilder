import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/player.dart';
import '../../../providers/image_providers.dart';
import '../../../services/image/image_storage_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/image_picker_field.dart';

/// Edit form for player details.
class PlayerEditForm extends ConsumerStatefulWidget {
  const PlayerEditForm({
    required this.player,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final Player player;
  final ValueChanged<Player> onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<PlayerEditForm> createState() => _PlayerEditFormState();
}

class _PlayerEditFormState extends ConsumerState<PlayerEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String? _pendingImagePath;
  bool _removeImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _notesController = TextEditingController(text: widget.player.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imagePath = widget.player.imagePath;

      if (_removeImage && imagePath != null) {
        final imageService = ref.read(imageStorageProvider);
        await imageService.deleteImage(
          entityType: 'players',
          entityId: widget.player.id,
        );
        imagePath = null;
      }

      if (_pendingImagePath != null) {
        final imageService = ref.read(imageStorageProvider);
        imagePath = await imageService.storeImage(
          sourcePath: _pendingImagePath!,
          entityType: 'players',
          entityId: widget.player.id,
          imageType: EntityImageType.avatar,
        );
      }

      final notes = _notesController.text.trim();
      final updated = widget.player.copyWith(
        name: _nameController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        imagePath: imagePath,
      );

      widget.onSave(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagePickerField(
            currentImagePath: _removeImage ? null : widget.player.imagePath,
            pendingImagePath: _pendingImagePath,
            fallbackIcon: Icons.person,
            isBanner: false,
            onImageSelected: (path) => setState(() {
              _pendingImagePath = path;
              _removeImage = false;
            }),
            onImageRemoved: () => setState(() {
              _pendingImagePath = null;
              _removeImage = true;
            }),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              hintText: 'Enter player name',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Player name is required'
                : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: Spacing.fieldSpacing),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional notes about this player',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: _isSaving ? null : _save,
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
