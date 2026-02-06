import 'package:flutter/material.dart';

import '../../theme/spacing.dart';

/// Status indicator for the email service availability.
class NotificationServiceStatus extends StatelessWidget {
  const NotificationServiceStatus({required this.available, super.key});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = available
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final icon = available ? Icons.check_circle_outline : Icons.info_outline;
    final text = available
        ? 'Email service configured'
        : 'Email service not configured (Resend API key required)';

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: Spacing.iconSize),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable section container for notification settings.
class NotificationSection extends StatelessWidget {
  const NotificationSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Toggle row for boolean settings.
class NotificationToggleRow extends StatelessWidget {
  const NotificationToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Status summary for notification configuration.
class NotificationStatusSummary extends StatelessWidget {
  const NotificationStatusSummary({required this.isConfigured, super.key});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isConfigured
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.notifications_active : Icons.notifications_off,
            color: isConfigured
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              isConfigured
                  ? 'Email notifications are enabled'
                  : 'Enter a valid email address to receive notifications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isConfigured
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
