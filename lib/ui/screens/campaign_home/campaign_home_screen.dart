import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../providers/campaign_providers.dart';
import '../../theme/spacing.dart';
import 'campaign_action_buttons.dart';
import 'campaign_header.dart';
import 'campaign_quick_links.dart';
import 'campaign_sessions_section.dart';

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
            CampaignHeader(detail: detail),
            const SizedBox(height: Spacing.xl),
            CampaignRecordButton(campaignId: detail.campaign.id),
            const SizedBox(height: Spacing.sm),
            CampaignAddSessionButton(campaignId: detail.campaign.id),
            const SizedBox(height: Spacing.xl),
            CampaignQuickLinksSection(detail: detail),
            const SizedBox(height: Spacing.xl),
            CampaignRecentSessionsSection(detail: detail),
          ],
        ),
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
