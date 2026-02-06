import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A reusable info card with an icon and message.
///
/// Used for displaying informational messages with a colored background.
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.message,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
