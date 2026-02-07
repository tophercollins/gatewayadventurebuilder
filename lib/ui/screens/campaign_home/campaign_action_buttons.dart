import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../theme/spacing.dart';

class CampaignRecordButton extends StatelessWidget {
  const CampaignRecordButton({required this.campaignId, super.key});

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

class CampaignAddSessionButton extends StatelessWidget {
  const CampaignAddSessionButton({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(Routes.addSessionPath(campaignId)),
      icon: const Icon(Icons.post_add),
      label: const Text('Add Session Manually'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Spacing.md),
      ),
    );
  }
}
