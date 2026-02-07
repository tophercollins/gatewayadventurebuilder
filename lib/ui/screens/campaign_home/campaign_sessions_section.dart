import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../data/models/session.dart';
import '../../../providers/campaign_providers.dart';
import '../../../utils/formatters.dart';
import '../../theme/spacing.dart';
import '../../widgets/status_badge.dart';

class CampaignRecentSessionsSection extends StatelessWidget {
  const CampaignRecentSessionsSection({required this.detail, super.key});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = detail.sessions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail.sessions.length > 5)
              TextButton(
                onPressed: () =>
                    context.go(Routes.sessionsListPath(detail.campaign.id)),
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        if (sessions.isEmpty)
          _EmptySessionsState(campaignId: detail.campaign.id)
        else
          ...sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _SessionCard(
                session: session,
                campaignId: detail.campaign.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.campaignId});

  final Session session;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      session.title ??
                          'Session ${session.sessionNumber ?? '?'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      formatDate(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(sessionStatus: session.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySessionsState extends StatelessWidget {
  const _EmptySessionsState({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('No sessions yet', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.xs),
          Text(
            'Record your first session to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
