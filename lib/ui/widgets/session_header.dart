import 'package:flutter/material.dart';

import '../../providers/session_detail_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import 'status_badge.dart';

/// Header for the session detail screen showing title, date, duration, and
/// an optional resync button when content has been edited.
class SessionHeader extends StatelessWidget {
  const SessionHeader({required this.detail, required this.onResync, super.key});

  final SessionDetailData detail;
  final VoidCallback onResync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = detail.session;

    final hasEdits =
        (detail.summary?.isEdited ?? false) ||
        detail.scenes.any((s) => s.isEdited) ||
        detail.npcs.any((n) => n.isEdited) ||
        detail.locations.any((l) => l.isEdited) ||
        detail.items.any((i) => i.isEdited) ||
        detail.actionItems.any((a) => a.isEdited) ||
        detail.playerMoments.any((m) => m.isEdited);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session.title ?? 'Session ${session.sessionNumber ?? '?'}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(sessionStatus: session.status),
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
                onPressed: onResync,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Resync'),
              ),
          ],
        ),
      ],
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
