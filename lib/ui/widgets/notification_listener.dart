import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_providers.dart';
import '../theme/spacing.dart';

/// Widget that listens for in-app notifications and shows snackbars.
/// Should be placed near the top of the widget tree.
class NotificationListener extends ConsumerStatefulWidget {
  const NotificationListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<NotificationListener> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState extends ConsumerState<NotificationListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<InAppNotification?>(
      inAppNotificationProvider,
      (previous, next) {
        if (next != null && previous != next) {
          _showNotification(context, next);
        }
      },
    );

    return widget.child;
  }

  void _showNotification(BuildContext context, InAppNotification notification) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Clear any existing snackbars
    messenger.clearSnackBars();

    // Determine colors based on type
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (notification.type) {
      case InAppNotificationType.success:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        icon = Icons.check_circle_outline;
      case InAppNotificationType.error:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.error_outline;
      case InAppNotificationType.info:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
        icon = Icons.info_outline;
    }

    // Build action button if session ID is provided
    SnackBarAction? action;
    if (notification.sessionId != null) {
      action = SnackBarAction(
        label: 'View',
        textColor: textColor,
        onPressed: () {
          // Navigate to session detail
          // We need campaign ID to navigate - for now just show a message
          // In production, this would be included in the notification
          messenger.clearSnackBars();
        },
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: Spacing.iconSize),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                notification.message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        margin: const EdgeInsets.all(Spacing.md),
        duration: const Duration(seconds: 5),
        action: action,
        dismissDirection: DismissDirection.horizontal,
        onVisible: () {
          // Clear the notification state after showing
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              ref.read(inAppNotificationProvider.notifier).clear();
            }
          });
        },
      ),
    );
  }
}

/// Banner widget that shows when a session is ready to review.
class ProcessingCompleteBanner extends ConsumerWidget {
  const ProcessingCompleteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(inAppNotificationProvider);

    if (notification == null ||
        notification.type != InAppNotificationType.success) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.onPrimaryContainer,
            size: Spacing.iconSizeCompact,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              notification.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(inAppNotificationProvider.notifier).clear();
            },
            child: Text(
              'Dismiss',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
