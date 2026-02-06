import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_moment.dart';
import '../../providers/editing_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';

/// An editable card widget for displaying a player moment/highlight.
class EditableMomentCard extends ConsumerStatefulWidget {
  const EditableMomentCard({
    required this.moment,
    required this.onUpdate,
    super.key,
  });

  final PlayerMoment moment;
  final void Function(PlayerMoment updated) onUpdate;

  @override
  ConsumerState<EditableMomentCard> createState() => _EditableMomentCardState();
}

class _EditableMomentCardState extends ConsumerState<EditableMomentCard> {
  bool _isEditing = false;
  late TextEditingController _descriptionController;
  late TextEditingController _quoteController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.moment.description);
    _quoteController =
        TextEditingController(text: widget.moment.quoteText ?? '');
  }

  @override
  void didUpdateWidget(EditableMomentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.moment != widget.moment) {
      _descriptionController.text = widget.moment.description;
      _quoteController.text = widget.moment.quoteText ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _descriptionController.text = widget.moment.description;
      _quoteController.text = widget.moment.quoteText ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _descriptionController.text = widget.moment.description;
      _quoteController.text = widget.moment.quoteText ?? '';
    });
  }

  Future<void> _saveEditing() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    final notifier = ref.read(playerMomentEditingProvider.notifier);
    final result = await notifier.updateMoment(
      widget.moment.id,
      description: description,
      quoteText: _quoteController.text.trim().isNotEmpty
          ? _quoteController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _isEditing = false);
      widget.onUpdate(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moment saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(playerMomentEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeInfo = _getMomentTypeInfo(widget.moment.momentType, theme);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: _isEditing
          ? _buildEditMode(theme)
          : _buildDisplayMode(theme, typeInfo),
    );
  }

  Widget _buildDisplayMode(
    ThemeData theme,
    ({String label, IconData icon, Color color}) typeInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MomentTypeBadge(
              label: typeInfo.label,
              icon: typeInfo.icon,
              color: typeInfo.color,
            ),
            if (widget.moment.isEdited) ...[
              const Spacer(),
              _EditedIndicator(),
            ] else
              const Spacer(),
            if (widget.moment.timestampMs != null)
              _TimestampBadge(ms: widget.moment.timestampMs!),
            const SizedBox(width: Spacing.sm),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: _startEditing,
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(widget.moment.description, style: theme.textTheme.bodyMedium),
        if (widget.moment.quoteText != null) ...[
          const SizedBox(height: Spacing.sm),
          _QuoteBlock(quote: widget.moment.quoteText!),
        ],
      ],
    );
  }

  Widget _buildEditMode(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _descriptionController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextField(
          controller: _quoteController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Quote (optional)',
            hintText: 'Enter a memorable quote...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
            ),
          ),
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

  ({String label, IconData icon, Color color}) _getMomentTypeInfo(
    String? type,
    ThemeData theme,
  ) {
    return switch (type) {
      'quote' => (
          label: 'Quote',
          icon: Icons.format_quote_outlined,
          color: Colors.blue,
        ),
      'roleplay' => (
          label: 'Roleplay',
          icon: Icons.theater_comedy_outlined,
          color: Colors.purple,
        ),
      'combat' => (
          label: 'Combat',
          icon: Icons.sports_martial_arts_outlined,
          color: Colors.red,
        ),
      'puzzle' => (
          label: 'Problem Solving',
          icon: Icons.lightbulb_outline,
          color: Colors.orange,
        ),
      'humor' => (
          label: 'Funny Moment',
          icon: Icons.sentiment_very_satisfied_outlined,
          color: Colors.amber,
        ),
      'teamwork' => (
          label: 'Teamwork',
          icon: Icons.group_outlined,
          color: Colors.green,
        ),
      _ => (
          label: 'Highlight',
          icon: Icons.star_outline,
          color: theme.colorScheme.primary,
        ),
    };
  }
}

class _MomentTypeBadge extends StatelessWidget {
  const _MomentTypeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimestampBadge extends StatelessWidget {
  const _TimestampBadge({required this.ms});

  final int ms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.xxs),
        Text(
          formatDuration(Duration(milliseconds: ms)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Text(
        '"$quote"',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
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
