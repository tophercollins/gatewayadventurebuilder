import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A reusable card widget for editing entity information (NPCs, locations, items).
/// Supports inline editing of name, subtitle (role/type), and description.
class EditableEntityCard extends StatefulWidget {
  const EditableEntityCard({
    required this.icon,
    required this.name,
    required this.onSave,
    this.subtitle,
    this.description,
    this.isEdited = false,
    this.subtitleLabel = 'Type',
    this.descriptionLabel = 'Description',
    super.key,
  });

  final IconData icon;
  final String name;
  final String? subtitle;
  final String? description;
  final bool isEdited;
  final String subtitleLabel;
  final String descriptionLabel;

  /// Called when the user saves the edited entity.
  final void Function({
    required String name,
    String? subtitle,
    String? description,
  }) onSave;

  @override
  State<EditableEntityCard> createState() => _EditableEntityCardState();
}

class _EditableEntityCardState extends State<EditableEntityCard> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _subtitleController = TextEditingController(text: widget.subtitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.description ?? '');
  }

  @override
  void didUpdateWidget(EditableEntityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      if (oldWidget.name != widget.name) {
        _nameController.text = widget.name;
      }
      if (oldWidget.subtitle != widget.subtitle) {
        _subtitleController.text = widget.subtitle ?? '';
      }
      if (oldWidget.description != widget.description) {
        _descriptionController.text = widget.description ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = widget.name;
      _subtitleController.text = widget.subtitle ?? '';
      _descriptionController.text = widget.description ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.name;
      _subtitleController.text = widget.subtitle ?? '';
      _descriptionController.text = widget.description ?? '';
    });
  }

  void _saveEditing() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isEditing = false);

    widget.onSave(
      name: name,
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: _isEditing ? _buildEditMode(theme) : _buildDisplayMode(theme),
    );
  }

  Widget _buildDisplayMode(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Icon(
            widget.icon,
            color: theme.colorScheme.primary,
            size: Spacing.iconSize,
          ),
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
                      widget.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.isEdited) _EditedIndicator(),
                ],
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (widget.description != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  widget.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          iconSize: Spacing.iconSizeCompact,
          color: theme.colorScheme.onSurfaceVariant,
          tooltip: 'Edit',
          onPressed: _startEditing,
        ),
      ],
    );
  }

  Widget _buildEditMode(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                widget.icon,
                color: theme.colorScheme.primary,
                size: Spacing.iconSize,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditField(
                    controller: _nameController,
                    label: 'Name',
                    autofocus: true,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _EditField(
                    controller: _subtitleController,
                    label: widget.subtitleLabel,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _EditField(
                    controller: _descriptionController,
                    label: widget.descriptionLabel,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            FilledButton.icon(
              onPressed: _saveEditing,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _EditedIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: Spacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Text(
        'Edited',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
