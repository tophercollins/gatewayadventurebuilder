import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A single breadcrumb segment.
class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  bool get isClickable => onTap != null;
}

/// Breadcrumb navigation for drill-down pages.
/// Shows the navigation path with clickable segments.
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({required this.items, super.key});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: Spacing.iconSizeCompact,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            _BreadcrumbSegment(item: items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbSegment extends StatelessWidget {
  const _BreadcrumbSegment({required this.item, required this.isLast});

  final BreadcrumbItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: isLast ? colorScheme.onSurface : colorScheme.primary,
      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
    );

    if (!item.isClickable || isLast) {
      return Text(item.label, style: textStyle);
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(Spacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xxs,
        ),
        child: Text(item.label, style: textStyle),
      ),
    );
  }
}
