import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A multi-line text widget that becomes editable on edit button tap.
/// Shows Save/Cancel buttons when in edit mode.
class EditableParagraph extends StatefulWidget {
  const EditableParagraph({
    required this.text,
    required this.onSave,
    this.label,
    this.placeholder = 'Enter text...',
    this.isEdited = false,
    this.enabled = true,
    this.textStyle,
    this.minLines = 3,
    this.maxLines = 10,
    this.showEditButton = true,
    this.editButtonPosition = EditButtonPosition.topRight,
    super.key,
  });

  /// The current text value.
  final String text;

  /// Called when the user saves the edited text.
  final void Function(String newText) onSave;

  /// Optional label shown above the text field.
  final String? label;

  /// Placeholder text when empty.
  final String placeholder;

  /// Whether this content has been user-edited.
  final bool isEdited;

  /// Whether editing is enabled.
  final bool enabled;

  /// Text style for display mode.
  final TextStyle? textStyle;

  /// Minimum lines for the text field.
  final int minLines;

  /// Maximum lines for the text field.
  final int maxLines;

  /// Whether to show the edit button.
  final bool showEditButton;

  /// Position of the edit button.
  final EditButtonPosition editButtonPosition;

  @override
  State<EditableParagraph> createState() => _EditableParagraphState();
}

enum EditButtonPosition { topRight, inline }

class _EditableParagraphState extends State<EditableParagraph> {
  late TextEditingController _controller;
  bool _isEditing = false;
  String _originalText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _originalText = widget.text;
  }

  @override
  void didUpdateWidget(EditableParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isEditing) {
      _controller.text = widget.text;
      _originalText = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _originalText = widget.text;
      _controller.text = widget.text;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = _originalText;
    });
  }

  void _saveEditing() {
    final newText = _controller.text.trim();
    setState(() {
      _isEditing = false;
    });
    if (newText != _originalText) {
      widget.onSave(newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle =
        widget.textStyle ?? theme.textTheme.bodyLarge?.copyWith(height: 1.6);

    if (_isEditing) {
      return _buildEditMode(theme, effectiveTextStyle);
    }

    return _buildDisplayMode(theme, effectiveTextStyle);
  }

  Widget _buildEditMode(ThemeData theme, TextStyle? textStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xs),
        ],
        TextField(
          controller: _controller,
          autofocus: true,
          style: textStyle,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            contentPadding: const EdgeInsets.all(Spacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _EditButtons(onCancel: _cancelEditing, onSave: _saveEditing),
      ],
    );
  }

  Widget _buildDisplayMode(ThemeData theme, TextStyle? textStyle) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (widget.isEdited) _EditedIndicator(),
            ],
          ),
          const SizedBox(height: Spacing.xs),
        ],
        Text(
          widget.text.isNotEmpty ? widget.text : widget.placeholder,
          style: textStyle?.copyWith(
            color: widget.text.isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        if (widget.isEdited && widget.label == null) ...[
          const SizedBox(height: Spacing.xs),
          _EditedIndicator(),
        ],
      ],
    );

    if (!widget.showEditButton || !widget.enabled) {
      return content;
    }

    if (widget.editButtonPosition == EditButtonPosition.topRight) {
      return Stack(
        children: [
          Padding(padding: const EdgeInsets.only(right: 40), child: content),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: 'Edit',
              onPressed: _startEditing,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
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
}

/// Buttons for save/cancel in edit mode.
class _EditButtons extends StatelessWidget {
  const _EditButtons({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

/// Indicator badge showing content has been edited.
class _EditedIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
