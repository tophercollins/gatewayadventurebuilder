import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A reusable card widget for displaying session review sections.
/// Used in Session Detail screen for Summary, Entities, Actions, Players.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.icon,
    required this.preview,
    required this.onViewMore,
    required this.onEdit,
    super.key,
  });

  final String title;
  final IconData icon;
  final String preview;
  final VoidCallback onViewMore;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onViewMore,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: Spacing.iconSizeCompact,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: Spacing.iconSizeCompact,
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onViewMore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View more',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Icon(
                          Icons.chevron_right,
                          size: Spacing.iconSizeCompact,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
