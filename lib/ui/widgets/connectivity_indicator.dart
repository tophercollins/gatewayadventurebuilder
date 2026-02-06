import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/queue_providers.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Subtle connectivity status indicator with pending queue badge.
/// Shows online/offline status and number of items waiting to be processed.
class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({
    this.showLabel = true,
    this.compact = false,
    super.key,
  });

  /// Whether to show the text label (Online/Offline).
  final bool showLabel;

  /// Whether to use compact styling.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final queueState = ref.watch(queueNotifierProvider);
    final connectivityStatus = queueState.isProcessing
        ? ConnectivityStatus.online
        : ref.watch(currentConnectivityProvider);

    final isOnline = connectivityStatus == ConnectivityStatus.online;
    final isOffline = connectivityStatus == ConnectivityStatus.offline;
    final pendingCount = queueState.pendingCount;
    final isProcessing = queueState.isProcessing;

    final statusColor = isOnline
        ? theme.brightness.success
        : isOffline
        ? colorScheme.error
        : colorScheme.outline; // Unknown/initializing

    final statusText = isProcessing
        ? 'Processing'
        : isOnline
        ? 'Online'
        : isOffline
        ? 'Offline'
        : 'Checking...';

    final iconSize = compact ? Spacing.iconSizeCompact : Spacing.iconSize;
    final badgeSize = compact ? 14.0 : 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status icon with optional pending badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.15),
              ),
              child: Center(
                child: isProcessing
                    ? SizedBox(
                        width: iconSize * 0.6,
                        height: iconSize * 0.6,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                        ),
                      )
                    : Container(
                        width: iconSize * 0.4,
                        height: iconSize * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
              ),
            ),

            // Pending count badge
            if (pendingCount > 0 && !isProcessing)
              Positioned(
                right: -badgeSize / 2,
                top: -badgeSize / 2,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                  child: Center(
                    child: Text(
                      pendingCount > 9 ? '9+' : pendingCount.toString(),
                      style: TextStyle(
                        fontSize: badgeSize * 0.6,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Label
        if (showLabel) ...[
          SizedBox(width: compact ? Spacing.xs : Spacing.sm),
          Text(
            statusText,
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.bodySmall)
                    ?.copyWith(color: statusColor, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}

/// Compact connectivity dot indicator without label.
/// Used in tight spaces like sidebar footer.
class ConnectivityDot extends ConsumerWidget {
  const ConnectivityDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectivityStatus = ref.watch(currentConnectivityProvider);
    final isOnline = connectivityStatus == ConnectivityStatus.online;

    final statusColor = isOnline
        ? theme.brightness == Brightness.light
              ? const Color(0xFF16A34A)
              : const Color(0xFF22C55E)
        : theme.colorScheme.error;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
    );
  }
}

/// Connectivity status bar shown at the bottom of screens when offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final connectivityStatus = ref.watch(currentConnectivityProvider);

    // Only show banner when explicitly offline, not when unknown/initializing
    if (connectivityStatus != ConnectivityStatus.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      color: colorScheme.error.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: Spacing.iconSizeCompact,
            color: colorScheme.error,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'You are offline. Sessions will be processed when connected.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Processing status banner showing current processing state.
class ProcessingBanner extends ConsumerWidget {
  const ProcessingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final queueState = ref.watch(queueNotifierProvider);

    if (!queueState.isProcessing) {
      return const SizedBox.shrink();
    }

    final processingColor = theme.brightness == Brightness.light
        ? const Color(0xFFF59E0B)
        : const Color(0xFFFBBF24);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      color: processingColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          SizedBox(
            width: Spacing.iconSizeCompact,
            height: Spacing.iconSizeCompact,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: queueState.progress,
              backgroundColor: processingColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(processingColor),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              queueState.stepDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${(queueState.progress * 100).toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: processingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
