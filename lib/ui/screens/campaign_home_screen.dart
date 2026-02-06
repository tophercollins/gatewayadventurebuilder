import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/campaign_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/status_badge.dart';

/// Campaign Home screen - dashboard for a single campaign.
/// Per APP_FLOW.md: name, game system, description, links to sessions/world/players.
class CampaignHomeScreen extends ConsumerWidget {
  const CampaignHomeScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(campaignDetailProvider(campaignId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
      data: (detail) {
        if (detail == null) {
          return const _NotFoundState();
        }
        return _CampaignContent(detail: detail);
      },
    );
  }
}

class _CampaignContent extends StatelessWidget {
  const _CampaignContent({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _CampaignHeader(detail: detail),
            const SizedBox(height: Spacing.xl),
            _RecordButton(campaignId: detail.campaign.id),
            const SizedBox(height: Spacing.xl),
            _QuickLinksSection(detail: detail),
            const SizedBox(height: Spacing.xl),
            _RecentSessionsSection(detail: detail),
          ],
        ),
      ),
    );
  }
}

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaign = detail.campaign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                campaign.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(status: campaign.status),
          ],
        ),
        if (campaign.gameSystem != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            campaign.gameSystem!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (campaign.description != null) ...[
          const SizedBox(height: Spacing.md),
          Text(campaign.description!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () => context.go(Routes.newSessionPath(campaignId)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fiber_manual_record,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Record New Session',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.book_outlined,
                title: 'Sessions',
                count: detail.sessions.length,
                onTap: () {
                  // Sessions are displayed in the Recent Sessions
                  // section below on this screen.
                },
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.public_outlined,
                title: 'World Database',
                subtitle: 'NPCs, Locations, Items',
                onTap: () =>
                    context.go(Routes.worldDatabasePath(detail.campaign.id)),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        _QuickLinkCard(
          icon: Icons.group_outlined,
          title: 'Players & Characters',
          count: detail.playerCount,
          onTap: () => context.go(Routes.playersPath(detail.campaign.id)),
        ),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: Spacing.iconSize,
                ),
              ),
              const SizedBox(width: Spacing.md),
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
                    if (subtitle != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (count != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        '$count total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({required this.detail});

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
                onPressed: () {
                  // All sessions are shown in this section;
                  // a dedicated sessions list screen can be added later.
                },
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

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('Campaign not found', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => context.go(Routes.campaigns),
            child: const Text('Back to Campaigns'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text('Something went wrong', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
