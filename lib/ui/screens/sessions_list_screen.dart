import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/session_detail_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/status_badge.dart';

/// Screen showing all sessions for a campaign.
class SessionsListScreen extends ConsumerWidget {
  const SessionsListScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(campaignSessionsProvider(campaignId));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading sessions: $error'),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return _EmptyState(campaignId: campaignId);
            }
            return _SessionsList(
              sessions: sessions,
              campaignId: campaignId,
            );
          },
        ),
      ),
    );
  }
}

class _SessionsList extends ConsumerWidget {
  const _SessionsList({required this.sessions, required this.campaignId});

  final List<Session> sessions;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: sessions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _Header(count: sessions.length);
        final session = sessions[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: _SessionCard(
            session: session,
            campaignId: campaignId,
            onDelete: () => _confirmDelete(context, ref, session),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final title = session.title ?? 'Session ${session.sessionNumber ?? '?'}';
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Delete Session',
      message:
          'This will permanently delete "$title" and all its data '
          '(audio, transcripts, summaries, entities, and action items). '
          'This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(sessionEditorProvider).deleteSession(session.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$title"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete session: $e')),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Text(
        '$count session${count == 1 ? '' : 's'}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.campaignId,
    required this.onDelete,
  });

  final Session session;
  final String campaignId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = session.title ?? 'Session ${session.sessionNumber ?? '?'}';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () =>
            context.go(Routes.sessionDetailPath(campaignId, session.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: Spacing.iconSizeCompact,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xxs),
                        Text(
                          formatDate(session.date),
                          style: theme.textTheme.bodySmall?.copyWith(
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
                          const SizedBox(width: Spacing.xxs),
                          Text(
                            formatDurationHuman(
                              Duration(seconds: session.durationSeconds!),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(sessionStatus: session.status),
              const SizedBox(width: Spacing.xs),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No sessions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Record or add a session to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => context.go(Routes.newSessionPath(campaignId)),
            icon: const Icon(Icons.mic),
            label: const Text('Record Session'),
          ),
        ],
      ),
    );
  }
}
