import 'package:flutter/material.dart';

import '../../data/models/session.dart';
import '../../providers/session_detail_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import 'status_badge.dart';

/// Header for the session detail screen showing title, date, duration, and
/// an optional resync button when content has been edited.
class SessionHeader extends StatefulWidget {
  const SessionHeader({
    required this.detail,
    required this.onResync,
    this.onTitleUpdated,
    super.key,
  });

  final SessionDetailData detail;
  final VoidCallback onResync;
  final ValueChanged<String>? onTitleUpdated;

  @override
  State<SessionHeader> createState() => _SessionHeaderState();
}

class _SessionHeaderState extends State<SessionHeader> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.detail.session.title ?? '',
    );
  }

  @override
  void didUpdateWidget(SessionHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingTitle &&
        oldWidget.detail.session.title != widget.detail.session.title) {
      _titleController.text = widget.detail.session.title ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty) {
      widget.onTitleUpdated?.call(newTitle);
    }
    setState(() => _isEditingTitle = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.detail.session;

    final hasEdits =
        (widget.detail.summary?.isEdited ?? false) ||
        widget.detail.scenes.any((s) => s.isEdited) ||
        widget.detail.npcs.any((n) => n.isEdited) ||
        widget.detail.locations.any((l) => l.isEdited) ||
        widget.detail.items.any((i) => i.isEdited) ||
        widget.detail.actionItems.any((a) => a.isEdited) ||
        widget.detail.playerMoments.any((m) => m.isEdited);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTitle(theme, session)),
            if (!_isEditingTitle) ...[
              if (widget.onTitleUpdated != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => setState(() => _isEditingTitle = true),
                  tooltip: 'Edit title',
                ),
              StatusBadge(sessionStatus: session.status),
            ],
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              formatDate(session.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (session.durationSeconds != null) ...[
              const SizedBox(width: Spacing.md),
              Icon(
                Icons.schedule_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                formatDurationHuman(
                  Duration(seconds: session.durationSeconds!),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            if (hasEdits)
              OutlinedButton.icon(
                onPressed: widget.onResync,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Resync'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, Session session) {
    if (_isEditingTitle) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _titleController,
              autofocus: true,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Session title',
                isDense: true,
              ),
              onFieldSubmitted: (_) => _saveTitle(),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: _saveTitle,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() {
              _titleController.text = widget.detail.session.title ?? '';
              _isEditingTitle = false;
            }),
            tooltip: 'Cancel',
          ),
        ],
      );
    }

    return Text(
      session.title ?? 'Session ${session.sessionNumber ?? '?'}',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Overlay shown during content resync.
class ResyncOverlay extends StatelessWidget {
  const ResyncOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: Spacing.md),
                Text('Resyncing content...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
