import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'entity_image.dart';

/// A reusable card widget for displaying entity information.
/// Used for NPCs, locations, and items in session entities screen.
class EntityCard extends StatelessWidget {
  const EntityCard({
    required this.icon,
    required this.name,
    this.subtitle,
    this.description,
    this.imagePath,
    required this.onEdit,
    super.key,
  });

  final IconData icon;
  final String name;
  final String? subtitle;
  final String? description;
  final String? imagePath;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntityImage.avatar(
            imagePath: imagePath,
            fallbackIcon: icon,
            size: 40,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (description != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
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
    );
  }
}
