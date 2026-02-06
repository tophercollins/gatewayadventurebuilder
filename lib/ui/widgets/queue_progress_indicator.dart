import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/queue_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Progress indicator for session cards showing processing progress.
/// Shows a linear progress bar when the session is being processed.
class SessionQueueProgress extends ConsumerWidget {
  const SessionQueueProgress({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isProcessing = ref.watch(isSessionProcessingProvider(sessionId));
    final progress = ref.watch(sessionProcessingProgressProvider(sessionId));

    if (!isProcessing || progress == null) {
      return const SizedBox.shrink();
    }

    final processingColor = theme.brightness.processing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.xxs),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: processingColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(processingColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

/// Detailed progress indicator with step description.
/// Used when more space is available (e.g., session detail page).
class SessionQueueProgressDetailed extends ConsumerWidget {
  const SessionQueueProgressDetailed({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isProcessing = ref.watch(isSessionProcessingProvider(sessionId));
    final queueState = ref.watch(queueNotifierProvider);

    if (!isProcessing) {
      return const SizedBox.shrink();
    }

    final processingColor = theme.brightness.processing;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: processingColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(
          color: processingColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: Spacing.iconSize,
                height: Spacing.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: queueState.progress,
                  backgroundColor: processingColor.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(processingColor),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Session',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      queueState.stepDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(queueState.progress * 100).toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: processingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacing.xxs),
            child: LinearProgressIndicator(
              value: queueState.progress,
              backgroundColor: processingColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(processingColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Queue status card showing overall queue state.
/// Used in dashboard or settings to show processing queue status.
class QueueStatusCard extends ConsumerWidget {
  const QueueStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final queueState = ref.watch(queueNotifierProvider);
    final isOnline = ref.watch(isOnlineProvider);

    final processingColor = theme.brightness.processing;

    final successColor = theme.brightness.success;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    if (queueState.isProcessing) {
      icon = Icons.sync;
      iconColor = processingColor;
      title = 'Processing';
      subtitle = queueState.stepDescription;
    } else if (queueState.pendingCount > 0) {
      if (isOnline) {
        icon = Icons.hourglass_empty;
        iconColor = colorScheme.primary;
        title = '${queueState.pendingCount} Pending';
        subtitle = 'Waiting to process...';
      } else {
        icon = Icons.cloud_off;
        iconColor = colorScheme.error;
        title = '${queueState.pendingCount} Queued';
        subtitle = 'Will process when online';
      }
    } else {
      icon = Icons.check_circle;
      iconColor = successColor;
      title = 'Up to Date';
      subtitle = 'No pending sessions';
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Spacing.cardRadius),
            ),
            child: queueState.isProcessing
                ? Padding(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: queueState.progress,
                      backgroundColor: iconColor.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 24),
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
                const SizedBox(height: Spacing.xxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (queueState.pendingCount > 0 && !queueState.isProcessing && isOnline)
            TextButton(
              onPressed: () {
                ref.read(queueNotifierProvider.notifier).processNow();
              },
              child: const Text('Process Now'),
            ),
        ],
      ),
    );
  }
}
