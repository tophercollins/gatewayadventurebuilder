import 'package:flutter/material.dart';

import '../../data/models/character.dart';
import '../theme/spacing.dart';

/// Inline form for editing character details.
class CharacterEditForm extends StatefulWidget {
  const CharacterEditForm({
    required this.character,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final Character character;
  final ValueChanged<Character> onSave;
  final VoidCallback onCancel;

  @override
  State<CharacterEditForm> createState() => _CharacterEditFormState();
}

class _CharacterEditFormState extends State<CharacterEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _classController;
  late final TextEditingController _raceController;
  late final TextEditingController _levelController;
  late final TextEditingController _backstoryController;
  late final TextEditingController _goalsController;
  late final TextEditingController _notesController;
  late CharacterStatus _status;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _classController = TextEditingController(
      text: widget.character.characterClass ?? '',
    );
    _raceController = TextEditingController(text: widget.character.race ?? '');
    _levelController = TextEditingController(
      text: widget.character.level?.toString() ?? '',
    );
    _backstoryController = TextEditingController(
      text: widget.character.backstory ?? '',
    );
    _goalsController = TextEditingController(
      text: widget.character.goals ?? '',
    );
    _notesController = TextEditingController(
      text: widget.character.notes ?? '',
    );
    _status = widget.character.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _raceController.dispose();
    _levelController.dispose();
    _backstoryController.dispose();
    _goalsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedCharacter = widget.character.copyWith(
      name: _nameController.text.trim(),
      characterClass: _classController.text.trim().isEmpty
          ? null
          : _classController.text.trim(),
      race: _raceController.text.trim().isEmpty
          ? null
          : _raceController.text.trim(),
      level: _levelController.text.trim().isEmpty
          ? null
          : int.tryParse(_levelController.text.trim()),
      backstory: _backstoryController.text.trim().isEmpty
          ? null
          : _backstoryController.text.trim(),
      goals: _goalsController.text.trim().isEmpty
          ? null
          : _goalsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: _status,
    );

    widget.onSave(updatedCharacter);
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
              labelText: 'Character Name',
              hintText: 'Enter character name',
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
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _raceController,
                  decoration: const InputDecoration(
                    labelText: 'Race',
                    hintText: 'e.g., Elf, Dwarf',
                  ),
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    hintText: 'e.g., Fighter, Wizard',
                  ),
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _levelController,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final level = int.tryParse(value);
                      if (level == null || level < 1) {
                        return 'Invalid level';
                      }
                    }
                    return null;
                  },
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: DropdownButtonFormField<CharacterStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: CharacterStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_formatStatus(status)),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            controller: _backstoryController,
            decoration: const InputDecoration(
              labelText: 'Backstory',
              hintText: 'Character background and history',
            ),
            maxLines: 3,
            enabled: !_isSaving,
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            controller: _goalsController,
            decoration: const InputDecoration(
              labelText: 'Goals',
              hintText: 'Character motivations and objectives',
            ),
            maxLines: 2,
            enabled: !_isSaving,
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional notes',
            ),
            maxLines: 2,
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

  String _formatStatus(CharacterStatus status) {
    return switch (status) {
      CharacterStatus.active => 'Active',
      CharacterStatus.retired => 'Retired',
      CharacterStatus.dead => 'Dead',
    };
  }
}
