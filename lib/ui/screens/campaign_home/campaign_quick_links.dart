import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../providers/campaign_providers.dart';
import '../../theme/spacing.dart';

class CampaignQuickLinksSection extends StatelessWidget {
  const CampaignQuickLinksSection({required this.detail, super.key});

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
                onTap: () =>
                    context.go(Routes.sessionsListPath(detail.campaign.id)),
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
        Row(
          children: [
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.group_outlined,
                title: 'Players',
                count: detail.playerCount,
                onTap: () => context.go(Routes.playersPath(detail.campaign.id)),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.shield_outlined,
                title: 'Characters',
                onTap: () =>
                    context.go(Routes.charactersPath(detail.campaign.id)),
              ),
            ),
          ],
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
