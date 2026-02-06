import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/action_item.dart';
import '../../providers/editing_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// What's Next drill-down screen.
/// Displays action items and plot threads from the session.
class SessionActionsScreen extends ConsumerWidget {
  const SessionActionsScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(sessionActionItemsProvider(sessionId));
    final editingState = ref.watch(actionItemEditingProvider);

    return Stack(
      children: [
        actionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(error: error.toString()),
          data: (actions) => _ActionsContent(
            sessionId: sessionId,
            actions: actions,
          ),
        ),
        if (editingState.isLoading) const _LoadingOverlay(),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _ActionsContent extends ConsumerStatefulWidget {
  const _ActionsContent({
    required this.sessionId,
    required this.actions,
  });

  final String sessionId;
  final List<ActionItem> actions;

  @override
  ConsumerState<_ActionsContent> createState() => _ActionsContentState();
}

class _ActionsContentState extends ConsumerState<_ActionsContent> {
  late List<ActionItem> _localActions;

  @override
  void initState() {
    super.initState();
    _localActions = List.from(widget.actions);
  }

  @override
  void didUpdateWidget(_ActionsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions) {
      _localActions = List.from(widget.actions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localActions.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_outlined,
        title: 'No action items',
        message:
            'Action items and plot threads will appear here once the session is processed.',
      );
    }

    // Group by type
    final plotThreads =
        _localActions.where((a) => a.actionType == 'plot_thread').toList();
    final actionItems =
        _localActions.where((a) => a.actionType != 'plot_thread').toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            if (actionItems.isNotEmpty) ...[
              _ActionSection(
                title: 'Action Items',
                icon: Icons.checklist_outlined,
                items: actionItems,
                onUpdate: _onUpdateItem,
              ),
              const SizedBox(height: Spacing.xl),
            ],
            if (plotThreads.isNotEmpty)
              _ActionSection(
                title: 'Plot Threads',
                icon: Icons.auto_stories_outlined,
                items: plotThreads,
                onUpdate: _onUpdateItem,
              ),
          ],
        ),
      ),
    );
  }

  void _onUpdateItem(ActionItem updated) {
    final index = _localActions.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      setState(() => _localActions[index] = updated);
    }
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.onUpdate,
  });

  final String title;
  final IconData icon;
  final List<ActionItem> items;
  final void Function(ActionItem updated) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: Spacing.iconSize, color: theme.colorScheme.primary),
            const SizedBox(width: Spacing.sm),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _EditableActionItemCard(
              item: item,
              onUpdate: onUpdate,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableActionItemCard extends ConsumerStatefulWidget {
  const _EditableActionItemCard({
    required this.item,
    required this.onUpdate,
  });

  final ActionItem item;
  final void Function(ActionItem updated) onUpdate;

  @override
  ConsumerState<_EditableActionItemCard> createState() =>
      _EditableActionItemCardState();
}

class _EditableActionItemCardState
    extends ConsumerState<_EditableActionItemCard> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late ActionItemStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    _selectedStatus = widget.item.status;
  }

  @override
  void didUpdateWidget(_EditableActionItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.item != widget.item) {
      _titleController.text = widget.item.title;
      _descriptionController.text = widget.item.description ?? '';
      _selectedStatus = widget.item.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _titleController.text = widget.item.title;
      _descriptionController.text = widget.item.description ?? '';
      _selectedStatus = widget.item.status;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleController.text = widget.item.title;
      _descriptionController.text = widget.item.description ?? '';
      _selectedStatus = widget.item.status;
    });
  }

  Future<void> _saveEditing() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final notifier = ref.read(actionItemEditingProvider.notifier);
    final result = await notifier.updateActionItem(
      widget.item.id,
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      status: _selectedStatus,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _isEditing = false);
      widget.onUpdate(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action item saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(actionItemEditingProvider).error;
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
    final statusInfo = _getStatusInfo(widget.item.status, theme);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: _isEditing
          ? _buildEditMode(theme)
          : _buildDisplayMode(theme, statusInfo),
    );
  }

  Widget _buildDisplayMode(
    ThemeData theme,
    ({String label, Color color}) statusInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusIndicator(
              status: widget.item.status,
              color: statusInfo.color,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                widget.item.status == ActionItemStatus.resolved
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                      ),
                      if (widget.item.isEdited) _EditedIndicator(),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  _StatusBadge(label: statusInfo.label, color: statusInfo.color),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: _startEditing,
            ),
          ],
        ),
        if (widget.item.description != null) ...[
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              widget.item.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditMode(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Title',
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
          controller: _descriptionController,
          maxLines: 2,
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
        DropdownButtonFormField<ActionItemStatus>(
          initialValue: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'Status',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.fieldRadius),
            ),
          ),
          items: ActionItemStatus.values.map((status) {
            final info = _getStatusInfo(status, theme);
            return DropdownMenuItem<ActionItemStatus>(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: info.color, width: 2),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(info.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStatus = value);
            }
          },
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

  ({String label, Color color}) _getStatusInfo(
    ActionItemStatus status,
    ThemeData theme,
  ) {
    return switch (status) {
      ActionItemStatus.open => (label: 'Open', color: theme.colorScheme.primary),
      ActionItemStatus.inProgress => (label: 'In Progress', color: Colors.orange),
      ActionItemStatus.resolved => (label: 'Resolved', color: Colors.green),
      ActionItemStatus.dropped => (
          label: 'Dropped',
          color: theme.colorScheme.onSurfaceVariant,
        ),
    };
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
    required this.color,
  });

  final ActionItemStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: status == ActionItemStatus.resolved
          ? Icon(Icons.check, size: 14, color: color)
          : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
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
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
