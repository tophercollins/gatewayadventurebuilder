import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/campaign.dart';
import '../../providers/campaign_providers.dart';
import '../theme/spacing.dart';
import '../widgets/status_badge.dart';

/// Campaigns list screen - displays all campaigns.
/// Per APP_FLOW.md: Tap to navigate to Campaign Home.
class CampaignsListScreen extends ConsumerWidget {
  const CampaignsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsListProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: campaignsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorState(error: error.toString()),
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return const _EmptyState();
            }
            return Stack(
              children: [
                _CampaignsList(campaigns: campaigns),
                Positioned(
                  bottom: Spacing.lg,
                  right: Spacing.lg,
                  child: FloatingActionButton(
                    onPressed: () => context.go(Routes.newCampaign),
                    tooltip: 'Create campaign',
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampaignsList extends StatelessWidget {
  const _CampaignsList({required this.campaigns});

  final List<CampaignWithSessionCount> campaigns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: campaigns.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.lg),
            child: Text(
              'Campaigns',
              style: theme.textTheme.headlineSmall,
            ),
          );
        }
        final item = campaigns[index - 1];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < campaigns.length ? Spacing.sm : 0,
          ),
          child: _CampaignCard(
            campaign: item.campaign,
            sessionCount: item.sessionCount,
          ),
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.sessionCount});

  final Campaign campaign;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasImage = campaign.imagePath != null &&
        campaign.imagePath!.isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () => context.go(Routes.campaignPath(campaign.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Spacing.cardRadius),
                    topRight: Radius.circular(Spacing.cardRadius),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 6,
                    child: Image.file(
                      File(campaign.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Spacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campaign.name,
                            style: theme.textTheme.titleMedium?.copyWith(
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: Spacing.iconSizeCompact,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '$sessionCount ${sessionCount == 1 ? 'session' : 'sessions'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No campaigns yet',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Create your first campaign to start tracking sessions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => context.go(Routes.newCampaign),
            icon: const Icon(Icons.add),
            label: const Text('Create your first campaign'),
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

    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
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
