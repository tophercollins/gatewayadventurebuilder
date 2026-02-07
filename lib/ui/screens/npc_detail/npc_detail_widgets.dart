import 'package:flutter/material.dart';

import '../../../data/models/npc.dart';
import '../../theme/spacing.dart';
import '../../widgets/entity_image.dart';

/// Header widget for NPC detail screen.
class NpcHeader extends StatelessWidget {
  const NpcHeader({required this.npc, required this.onEdit, super.key});

  final Npc npc;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        EntityImage.avatar(
          imagePath: npc.imagePath,
          fallbackIcon: Icons.person_outline,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      npc.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (npc.isEdited)
                    Tooltip(
                      message: 'Manually edited',
                      child: Icon(
                        Icons.edit_note,
                        size: Spacing.iconSizeCompact,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              if (npc.role != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  npc.role!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
      ],
    );
  }
}

/// Info section showing NPC status, description, and notes.
class NpcInfoSection extends StatelessWidget {
  const NpcInfoSection({required this.npc, super.key});

  final Npc npc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Status', value: npc.status.name.toUpperCase()),
          if (npc.description != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(npc.description!, style: theme.textTheme.bodyMedium),
          ],
          if (npc.notes != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(npc.notes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Simple label-value row.
class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
