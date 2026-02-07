import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/entity_appearance.dart';
import '../../data/models/organisation.dart';
import '../../data/models/session.dart';
import '../../utils/formatters.dart';
import '../../providers/world_providers.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// Organisation detail screen showing all organisation information and appearances.
class OrganisationDetailScreen extends ConsumerStatefulWidget {
  const OrganisationDetailScreen({
    required this.campaignId,
    required this.organisationId,
    super.key,
  });

  final String campaignId;
  final String organisationId;

  @override
  ConsumerState<OrganisationDetailScreen> createState() =>
      _OrganisationDetailScreenState();
}

class _OrganisationDetailScreenState
    extends ConsumerState<OrganisationDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(
      organisationByIdProvider(widget.organisationId),
    );
    final sessionsAsync = ref.watch(
      entitySessionsProvider((
        type: EntityType.organisation,
        entityId: widget.organisationId,
      )),
    );

    return orgAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (organisation) {
        if (organisation == null) {
          return const NotFoundState(message: 'Organisation not found');
        }
        return _OrganisationDetailContent(
          organisation: organisation,
          campaignId: widget.campaignId,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Organisation updated) async {
    await ref.read(entityEditorProvider).updateOrganisation(updated);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation updated')),
      );
    }
  }
}

class _OrganisationDetailContent extends StatelessWidget {
  const _OrganisationDetailContent({
    required this.organisation,
    required this.campaignId,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Organisation organisation;
  final String campaignId;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Organisation> onSave;

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
              _OrganisationHeader(
                organisation: organisation,
                onEdit: onEditToggle,
              ),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                _OrganisationEditForm(
                  organisation: organisation,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                _OrganisationInfoSection(organisation: organisation),
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

class _OrganisationHeader extends StatelessWidget {
  const _OrganisationHeader({
    required this.organisation,
    required this.onEdit,
  });

  final Organisation organisation;
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
            Icons.groups_outlined,
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
                      organisation.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (organisation.isEdited)
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
              if (organisation.organisationType != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  organisation.organisationType!,
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

class _OrganisationInfoSection extends StatelessWidget {
  const _OrganisationInfoSection({required this.organisation});

  final Organisation organisation;

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
          if (organisation.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              organisation.description!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (organisation.notes != null) ...[
            if (organisation.description != null)
              const SizedBox(height: Spacing.md),
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(organisation.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (organisation.description == null && organisation.notes == null)
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
                      session.title ??
                          'Session ${session.sessionNumber ?? ""}',
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

class _OrganisationEditForm extends StatefulWidget {
  const _OrganisationEditForm({
    required this.organisation,
    required this.onSave,
    required this.onCancel,
  });

  final Organisation organisation;
  final ValueChanged<Organisation> onSave;
  final VoidCallback onCancel;

  @override
  State<_OrganisationEditForm> createState() => _OrganisationEditFormState();
}

class _OrganisationEditFormState extends State<_OrganisationEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organisation.name);
    _typeController = TextEditingController(
      text: widget.organisation.organisationType ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.organisation.description ?? '',
    );
    _notesController = TextEditingController(
      text: widget.organisation.notes ?? '',
    );
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

    final updated = widget.organisation.copyWith(
      name: _nameController.text.trim(),
      organisationType: _typeController.text.trim().isEmpty
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
                hintText: 'e.g., guild, faction, government',
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
