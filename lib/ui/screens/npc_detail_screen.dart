import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/npc.dart';
import '../../data/models/npc_quote.dart';
import '../../data/models/npc_relationship.dart';
import '../../data/models/session.dart';
import '../../providers/repository_providers.dart';
import '../../providers/world_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// NPC detail screen showing all NPC information, relationships, and quotes.
class NpcDetailScreen extends ConsumerStatefulWidget {
  const NpcDetailScreen({
    required this.campaignId,
    required this.npcId,
    super.key,
  });

  final String campaignId;
  final String npcId;

  @override
  ConsumerState<NpcDetailScreen> createState() => _NpcDetailScreenState();
}

class _NpcDetailScreenState extends ConsumerState<NpcDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final npcAsync = ref.watch(npcByIdProvider(widget.npcId));
    final relationshipsAsync = ref.watch(npcRelationshipsProvider(widget.npcId));
    final quotesAsync = ref.watch(npcQuotesProvider(widget.npcId));
    final sessionsAsync = ref.watch(
      entitySessionsProvider((type: EntityType.npc, entityId: widget.npcId)),
    );

    return npcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (npc) {
        if (npc == null) {
          return const NotFoundState(message: 'NPC not found');
        }
        return _NpcDetailContent(
          npc: npc,
          campaignId: widget.campaignId,
          relationshipsAsync: relationshipsAsync,
          quotesAsync: quotesAsync,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Npc updatedNpc) async {
    final entityRepo = ref.read(entityRepositoryProvider);
    await entityRepo.updateNpc(updatedNpc, markEdited: true);
    ref.invalidate(npcByIdProvider(widget.npcId));
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NPC updated')),
      );
    }
  }
}

class _NpcDetailContent extends StatelessWidget {
  const _NpcDetailContent({
    required this.npc,
    required this.campaignId,
    required this.relationshipsAsync,
    required this.quotesAsync,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Npc npc;
  final String campaignId;
  final AsyncValue<List<NpcRelationship>> relationshipsAsync;
  final AsyncValue<List<NpcQuote>> quotesAsync;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Npc> onSave;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NpcHeader(npc: npc, onEdit: onEditToggle),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                _NpcEditForm(
                  npc: npc,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                _NpcInfoSection(npc: npc),
                const SizedBox(height: Spacing.lg),
                _RelationshipsSection(
                  relationshipsAsync: relationshipsAsync,
                  campaignId: campaignId,
                ),
                const SizedBox(height: Spacing.lg),
                _QuotesSection(
                  quotesAsync: quotesAsync,
                  campaignId: campaignId,
                ),
                const SizedBox(height: Spacing.lg),
                _AppearancesSection(
                  sessionsAsync: sessionsAsync,
                  campaignId: campaignId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NpcHeader extends StatelessWidget {
  const _NpcHeader({required this.npc, required this.onEdit});

  final Npc npc;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Icon(
            Icons.person_outline,
            color: theme.colorScheme.primary,
            size: 32,
          ),
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

class _NpcInfoSection extends StatelessWidget {
  const _NpcInfoSection({required this.npc});

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
          _InfoRow(label: 'Status', value: npc.status.name.toUpperCase()),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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

class _RelationshipsSection extends ConsumerWidget {
  const _RelationshipsSection({
    required this.relationshipsAsync,
    required this.campaignId,
  });

  final AsyncValue<List<NpcRelationship>> relationshipsAsync;
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationships',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        relationshipsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (relationships) {
            if (relationships.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.people_outline,
                message: 'No known relationships with player characters.',
              );
            }
            return Column(
              children: relationships.map((rel) {
                return _RelationshipCard(relationship: rel);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RelationshipCard extends ConsumerWidget {
  const _RelationshipCard({required this.relationship});

  final NpcRelationship relationship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final characterAsync =
        ref.watch(characterByIdProvider(relationship.characterId));

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            _sentimentIcon(relationship.sentiment),
            color: _sentimentColor(theme, relationship.sentiment),
            size: Spacing.iconSize,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                characterAsync.when(
                  loading: () => const Text('Loading...'),
                  error: (e, _) => const Text('Unknown'),
                  data: (character) => Text(
                    character?.name ?? 'Unknown Character',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (relationship.relationship != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    relationship.relationship!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _sentimentColor(theme, relationship.sentiment)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Spacing.badgeRadius),
            ),
            child: Text(
              relationship.sentiment.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _sentimentColor(theme, relationship.sentiment),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _sentimentIcon(RelationshipSentiment sentiment) {
    switch (sentiment) {
      case RelationshipSentiment.friendly:
        return Icons.favorite_outline;
      case RelationshipSentiment.hostile:
        return Icons.dangerous_outlined;
      case RelationshipSentiment.neutral:
        return Icons.remove_circle_outline;
      case RelationshipSentiment.unknown:
        return Icons.help_outline;
    }
  }

  Color _sentimentColor(ThemeData theme, RelationshipSentiment sentiment) {
    switch (sentiment) {
      case RelationshipSentiment.friendly:
        return Colors.green;
      case RelationshipSentiment.hostile:
        return theme.colorScheme.error;
      case RelationshipSentiment.neutral:
        return theme.colorScheme.onSurfaceVariant;
      case RelationshipSentiment.unknown:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

class _QuotesSection extends StatelessWidget {
  const _QuotesSection({
    required this.quotesAsync,
    required this.campaignId,
  });

  final AsyncValue<List<NpcQuote>> quotesAsync;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notable Quotes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        quotesAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (quotes) {
            if (quotes.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.format_quote_outlined,
                message: 'No notable quotes recorded.',
              );
            }
            return Column(
              children: quotes
                  .take(5)
                  .map((quote) => _QuoteCard(quote: quote))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final NpcQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  quote.quoteText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          if (quote.context != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              quote.context!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppearancesSection extends StatelessWidget {
  const _AppearancesSection({
    required this.sessionsAsync,
    required this.campaignId,
  });

  final AsyncValue<List<Session>> sessionsAsync;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appeared In',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        sessionsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.history,
                message: 'No session appearances recorded.',
              );
            }
            return Column(
              children: sessions
                  .map((session) => _SessionCard(
                        session: session,
                        campaignId: campaignId,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.campaignId});

  final Session session;
  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          Routes.sessionDetailPath(campaignId, session.id),
        ),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title ??
                          'Session ${session.sessionNumber ?? ""}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      _formatDate(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _NpcEditForm extends StatefulWidget {
  const _NpcEditForm({
    required this.npc,
    required this.onSave,
    required this.onCancel,
  });

  final Npc npc;
  final ValueChanged<Npc> onSave;
  final VoidCallback onCancel;

  @override
  State<_NpcEditForm> createState() => _NpcEditFormState();
}

class _NpcEditFormState extends State<_NpcEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late NpcStatus _status;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.npc.name);
    _roleController = TextEditingController(text: widget.npc.role ?? '');
    _descriptionController =
        TextEditingController(text: widget.npc.description ?? '');
    _notesController = TextEditingController(text: widget.npc.notes ?? '');
    _status = widget.npc.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.npc.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: _status,
    );

    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                hintText: 'e.g., ally, enemy, merchant',
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            DropdownButtonFormField<NpcStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: NpcStatus.values.map((s) {
                return DropdownMenuItem<NpcStatus>(value: s, child: Text(s.name));
              }).toList(),
              onChanged: _isSaving ? null : (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.fieldSpacing),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: Spacing.sm),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
