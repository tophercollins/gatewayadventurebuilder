import 'package:flutter/material.dart';

import '../../data/models/player.dart';
import '../theme/spacing.dart';

/// Inline form for editing player details.
class PlayerEditForm extends StatefulWidget {
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
  State<PlayerEditForm> createState() => _PlayerEditFormState();
}

class _PlayerEditFormState extends State<PlayerEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedPlayer = widget.player.copyWith(
      name: _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    widget.onSave(updatedPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              hintText: 'Enter player name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Spacing.fieldSpacing),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional notes about this player',
            ),
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
    );
  }
}
