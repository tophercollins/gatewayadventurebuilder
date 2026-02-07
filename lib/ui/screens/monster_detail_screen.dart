import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/monster.dart';
import '../../data/models/session.dart';
import '../../providers/world_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/entity_image.dart';

/// Monster detail screen showing all monster information and appearances.
class MonsterDetailScreen extends ConsumerStatefulWidget {
  const MonsterDetailScreen({
    required this.campaignId,
    required this.monsterId,
    super.key,
  });

  final String campaignId;
  final String monsterId;

  @override
  ConsumerState<MonsterDetailScreen> createState() =>
      _MonsterDetailScreenState();
}

class _MonsterDetailScreenState extends ConsumerState<MonsterDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final monsterAsync = ref.watch(monsterByIdProvider(widget.monsterId));
    final sessionsAsync = ref.watch(
      entitySessionsProvider((
        type: EntityType.monster,
        entityId: widget.monsterId,
      )),
    );

    return monsterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (monster) {
        if (monster == null) {
          return const NotFoundState(message: 'Monster not found');
        }
        return _MonsterDetailContent(
          monster: monster,
          campaignId: widget.campaignId,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Monster updatedMonster) async {
    await ref.read(entityEditorProvider).updateMonster(updatedMonster);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Monster updated')));
    }
  }
}

class _MonsterDetailContent extends StatelessWidget {
  const _MonsterDetailContent({
    required this.monster,
    required this.campaignId,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Monster monster;
  final String campaignId;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Monster> onSave;

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
              _MonsterHeader(monster: monster, onEdit: onEditToggle),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                _MonsterEditForm(
                  monster: monster,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                _MonsterInfoSection(monster: monster),
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

class _MonsterHeader extends StatelessWidget {
  const _MonsterHeader({required this.monster, required this.onEdit});

  final Monster monster;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        EntityImage.avatar(
          imagePath: monster.imagePath,
          fallbackIcon: Icons.pest_control_outlined,
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
                      monster.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (monster.isEdited)
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
              if (monster.monsterType != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  monster.monsterType!,
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

class _MonsterInfoSection extends StatelessWidget {
  const _MonsterInfoSection({required this.monster});

  final Monster monster;

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
          if (monster.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(monster.description!, style: theme.textTheme.bodyMedium),
          ],
          if (monster.notes != null) ...[
            if (monster.description != null) const SizedBox(height: Spacing.md),
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(monster.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (monster.description == null && monster.notes == null)
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
                      formatDate(session.date),
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
}

class _MonsterEditForm extends StatefulWidget {
  const _MonsterEditForm({
    required this.monster,
    required this.onSave,
    required this.onCancel,
  });

  final Monster monster;
  final ValueChanged<Monster> onSave;
  final VoidCallback onCancel;

  @override
  State<_MonsterEditForm> createState() => _MonsterEditFormState();
}

class _MonsterEditFormState extends State<_MonsterEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.monster.name);
    _typeController = TextEditingController(
      text: widget.monster.monsterType ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.monster.description ?? '',
    );
    _notesController = TextEditingController(text: widget.monster.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.monster.copyWith(
      name: _nameController.text.trim(),
      monsterType: _typeController.text.trim().isEmpty
          ? null
          : _typeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
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
                hintText: 'e.g., dragon, undead, beast',
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
