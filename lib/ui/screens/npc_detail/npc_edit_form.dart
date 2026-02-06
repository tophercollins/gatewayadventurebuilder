import 'package:flutter/material.dart';

import '../../../data/models/npc.dart';
import '../../theme/spacing.dart';

/// Edit form for modifying NPC details.
class NpcEditForm extends StatefulWidget {
  const NpcEditForm({
    required this.npc,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final Npc npc;
  final ValueChanged<Npc> onSave;
  final VoidCallback onCancel;

  @override
  State<NpcEditForm> createState() => _NpcEditFormState();
}

class _NpcEditFormState extends State<NpcEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late NpcStatus _status;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.npc.name);
    _roleController = TextEditingController(text: widget.npc.role ?? '');
    _descriptionController =
        TextEditingController(text: widget.npc.description ?? '');
    _notesController = TextEditingController(text: widget.npc.notes ?? '');
    _status = widget.npc.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.npc.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: _status,
    );

    widget.onSave(updated);
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                hintText: 'e.g., ally, enemy, merchant',
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            DropdownButtonFormField<NpcStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: NpcStatus.values.map((s) {
                return DropdownMenuItem<NpcStatus>(value: s, child: Text(s.name));
              }).toList(),
              onChanged: _isSaving ? null : (v) => setState(() => _status = v!),
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
