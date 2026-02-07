import 'package:flutter/material.dart';

import '../../data/models/player_moment.dart';
import '../../utils/formatters.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A card widget for displaying a player moment/highlight.
class MomentCard extends StatelessWidget {
  const MomentCard({required this.moment, required this.onEdit, super.key});

  final PlayerMoment moment;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeInfo = _getMomentTypeInfo(moment.momentType, theme);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MomentTypeBadge(
                label: typeInfo.label,
                icon: typeInfo.icon,
                color: typeInfo.color,
              ),
              const Spacer(),
              if (moment.timestampMs != null)
                _TimestampBadge(ms: moment.timestampMs!),
              const SizedBox(width: Spacing.sm),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                iconSize: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'Edit',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(moment.description, style: theme.textTheme.bodyMedium),
          if (moment.quoteText != null) ...[
            const SizedBox(height: Spacing.sm),
            _QuoteBlock(quote: moment.quoteText!),
          ],
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _getMomentTypeInfo(
    String? type,
    ThemeData theme,
  ) {
    final b = theme.brightness;
    return switch (type) {
      'quote' => (
        label: 'Quote',
        icon: Icons.format_quote_outlined,
        color: b.momentQuote,
      ),
      'roleplay' => (
        label: 'Roleplay',
        icon: Icons.theater_comedy_outlined,
        color: b.momentRoleplay,
      ),
      'combat' => (
        label: 'Combat',
        icon: Icons.sports_martial_arts_outlined,
        color: b.momentCombat,
      ),
      'puzzle' => (
        label: 'Problem Solving',
        icon: Icons.lightbulb_outline,
        color: b.momentPuzzle,
      ),
      'humor' => (
        label: 'Funny Moment',
        icon: Icons.sentiment_very_satisfied_outlined,
        color: b.momentHumor,
      ),
      'teamwork' => (
        label: 'Teamwork',
        icon: Icons.group_outlined,
        color: b.momentTeamwork,
      ),
      _ => (
        label: 'Highlight',
        icon: Icons.star_outline,
        color: theme.colorScheme.primary,
      ),
    };
  }
}

class _MomentTypeBadge extends StatelessWidget {
  const _MomentTypeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimestampBadge extends StatelessWidget {
  const _TimestampBadge({required this.ms});

  final int ms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.xxs),
        Text(
          formatDuration(Duration(milliseconds: ms)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Text(
        '"$quote"',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
