import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/item.dart';
import '../../data/models/session.dart';
import '../../providers/repository_providers.dart';
import '../../providers/world_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// Item detail screen showing all item information and appearances.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({
    required this.campaignId,
    required this.itemId,
    super.key,
  });

  final String campaignId;
  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemByIdProvider(widget.itemId));
    final sessionsAsync = ref.watch(
      entitySessionsProvider((type: EntityType.item, entityId: widget.itemId)),
    );

    return itemAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (item) {
        if (item == null) {
          return const NotFoundState(message: 'Item not found');
        }
        return _ItemDetailContent(
          item: item,
          campaignId: widget.campaignId,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Item updatedItem) async {
    final entityRepo = ref.read(entityRepositoryProvider);
    await entityRepo.updateItem(updatedItem, markEdited: true);
    ref.invalidate(itemByIdProvider(widget.itemId));
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item updated')));
    }
  }
}

class _ItemDetailContent extends StatelessWidget {
  const _ItemDetailContent({
    required this.item,
    required this.campaignId,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Item item;
  final String campaignId;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Item> onSave;

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
              _ItemHeader(item: item, onEdit: onEditToggle),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                _ItemEditForm(
                  item: item,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                _ItemInfoSection(item: item),
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

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item, required this.onEdit});

  final Item item;
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
            Icons.inventory_2_outlined,
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
                      item.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.isEdited)
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
              if (item.itemType != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  item.itemType!,
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

class _ItemInfoSection extends StatelessWidget {
  const _ItemInfoSection({required this.item});

  final Item item;

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
          if (item.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(item.description!, style: theme.textTheme.bodyMedium),
          ],
          if (item.properties != null) ...[
            if (item.description != null) const SizedBox(height: Spacing.md),
            Text(
              'Properties',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(item.properties!, style: theme.textTheme.bodyMedium),
          ],
          if (item.notes != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(item.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (item.description == null &&
              item.properties == null &&
              item.notes == null)
            Text(
              'No additional details available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
                  .map(
                    (session) =>
                        _SessionCard(session: session, campaignId: campaignId),
                  )
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
        onTap: () =>
            context.push(Routes.sessionDetailPath(campaignId, session.id)),
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
                      session.title ?? 'Session ${session.sessionNumber ?? ""}',
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

class _ItemEditForm extends StatefulWidget {
  const _ItemEditForm({
    required this.item,
    required this.onSave,
    required this.onCancel,
  });

  final Item item;
  final ValueChanged<Item> onSave;
  final VoidCallback onCancel;

  @override
  State<_ItemEditForm> createState() => _ItemEditFormState();
}

class _ItemEditFormState extends State<_ItemEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _propertiesController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _typeController = TextEditingController(text: widget.item.itemType ?? '');
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _propertiesController = TextEditingController(
      text: widget.item.properties ?? '',
    );
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _propertiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      itemType: _typeController.text.trim().isEmpty
          ? null
          : _typeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      properties: _propertiesController.text.trim().isEmpty
          ? null
          : _propertiesController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'e.g., weapon, armor, consumable',
              ),
              enabled: !_isSaving,
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
              controller: _propertiesController,
              decoration: const InputDecoration(
                labelText: 'Properties',
                hintText: 'Magical/special properties',
              ),
              maxLines: 2,
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
