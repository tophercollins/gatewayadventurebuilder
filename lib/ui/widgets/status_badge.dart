import 'package:flutter/material.dart';

import '../../data/models/campaign.dart';
import '../../data/models/session.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Status badge widget for campaigns and sessions.
/// Per FRONTEND_GUIDELINES.md: pill shape, status color at 15% opacity bg.
class StatusBadge extends StatelessWidget {
  const StatusBadge({this.status, this.sessionStatus, super.key})
    : assert(status != null || sessionStatus != null);

  final CampaignStatus? status;
  final SessionStatus? sessionStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, color) = _getStatusInfo(theme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.badgePaddingHorizontal,
        vertical: Spacing.badgePaddingVertical,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo(ThemeData theme) {
    if (status != null) {
      return switch (status!) {
        CampaignStatus.active => ('Active', theme.colorScheme.primary),
        CampaignStatus.paused => ('Paused', theme.colorScheme.onSurfaceVariant),
        CampaignStatus.completed => ('Completed', theme.brightness.success),
      };
    }

    if (sessionStatus != null) {
      return switch (sessionStatus!) {
        SessionStatus.recording => ('Recording', theme.brightness.recording),
        SessionStatus.transcribing => ('Transcribing', theme.brightness.processing),
        SessionStatus.processing => ('Processing', theme.brightness.processing),
        SessionStatus.queued => ('Queued', theme.brightness.queued),
        SessionStatus.complete => ('Complete', theme.brightness.complete),
        SessionStatus.error => ('Failed', theme.colorScheme.error),
      };
    }

    return ('Unknown', theme.colorScheme.onSurfaceVariant);
  }
}
