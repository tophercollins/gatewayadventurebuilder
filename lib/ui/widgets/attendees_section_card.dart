import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_detail_providers.dart';
import '../theme/spacing.dart';
import 'edit_attendees_dialog.dart';

/// Card displaying session attendees with an edit button.
/// Shows player names with their character names.
class AttendeesSectionCard extends ConsumerWidget {
  const AttendeesSectionCard({
    required this.sessionId,
    required this.campaignId,
    super.key,
  });

  final String sessionId;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attendeesAsync = ref.watch(sessionAttendeesProvider(sessionId));

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  Icons.group_outlined,
                  color: theme.colorScheme.primary,
                  size: Spacing.iconSizeCompact,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Attendees',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                iconSize: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'Edit attendees',
                onPressed: () => _showEditDialog(context),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // Attendee list
          attendeesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Text(
              'Failed to load attendees',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            data: (attendees) {
              if (attendees.isEmpty) {
                return Text(
                  'No attendees recorded',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attendees
                    .map((a) => _AttendeeRow(detail: a))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          EditAttendeesDialog(sessionId: sessionId, campaignId: campaignId),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.detail});

  final AttendeeDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = detail.character != null
        ? '${detail.player.name} as ${detail.character!.name}'
        : '${detail.player.name} (no character)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxs),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
