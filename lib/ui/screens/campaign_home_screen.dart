import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/campaign_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/status_badge.dart';

/// Campaign Home screen - dashboard for a single campaign.
/// Per APP_FLOW.md: name, game system, description, links to sessions/world/players.
class CampaignHomeScreen extends ConsumerWidget {
  const CampaignHomeScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(campaignDetailProvider(campaignId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
      data: (detail) {
        if (detail == null) {
          return const _NotFoundState();
        }
        return _CampaignContent(detail: detail);
      },
    );
  }
}

class _CampaignContent extends StatelessWidget {
  const _CampaignContent({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _CampaignHeader(detail: detail),
            const SizedBox(height: Spacing.xl),
            _RecordButton(campaignId: detail.campaign.id),
            const SizedBox(height: Spacing.sm),
            _AddSessionButton(campaignId: detail.campaign.id),
            const SizedBox(height: Spacing.xl),
            _QuickLinksSection(detail: detail),
            const SizedBox(height: Spacing.xl),
            _RecentSessionsSection(detail: detail),
          ],
        ),
      ),
    );
  }
}

class _CampaignHeader extends ConsumerStatefulWidget {
  const _CampaignHeader({required this.detail});

  final CampaignDetail detail;

  @override
  ConsumerState<_CampaignHeader> createState() => _CampaignHeaderState();
}

class _CampaignHeaderState extends ConsumerState<_CampaignHeader> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedGameSystem;
  String? _customGameSystem;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final campaign = widget.detail.campaign;
    _nameController = TextEditingController(text: campaign.name);
    _descriptionController = TextEditingController(
      text: campaign.description ?? '',
    );
    _syncGameSystem();
  }

  void _refreshEditFields() {
    final campaign = widget.detail.campaign;
    _nameController.text = campaign.name;
    _descriptionController.text = campaign.description ?? '';
    _syncGameSystem();
  }

  void _syncGameSystem() {
    final system = widget.detail.campaign.gameSystem;
    if (system != null && gameSystems.contains(system)) {
      _selectedGameSystem = system;
      _customGameSystem = null;
    } else if (system != null) {
      _selectedGameSystem = 'Other';
      _customGameSystem = system;
    } else {
      _selectedGameSystem = null;
      _customGameSystem = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getGameSystem() {
    if (_selectedGameSystem == 'Other') {
      return _customGameSystem?.trim();
    }
    return _selectedGameSystem;
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final updated = widget.detail.campaign.copyWith(
        name: _nameController.text.trim(),
        gameSystem: _getGameSystem(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await ref.read(campaignEditorProvider).updateCampaign(updated);
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update campaign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCampaign() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Delete Campaign',
      message:
          'This will permanently delete this campaign and all its sessions. '
          'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(campaignEditorProvider).deleteCampaign(
        widget.detail.campaign.id,
      );
      if (mounted) context.go(Routes.campaigns);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete campaign: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) return _buildEditForm(Theme.of(context));
    return _buildDisplay(Theme.of(context));
  }

  Widget _buildDisplay(ThemeData theme) {
    final campaign = widget.detail.campaign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                campaign.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(status: campaign.status),
            const SizedBox(width: Spacing.xs),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _refreshEditFields();
                  setState(() => _isEditing = true);
                } else if (value == 'delete') {
                  _deleteCampaign();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: Spacing.sm),
                      Text('Edit Campaign'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outlined,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Delete Campaign',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (campaign.gameSystem != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            campaign.gameSystem!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (campaign.description != null) ...[
          const SizedBox(height: Spacing.md),
          Text(campaign.description!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Campaign',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Campaign Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campaign name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedGameSystem,
            hint: const Text('Select game system'),
            items: gameSystems.map((system) {
              return DropdownMenuItem(value: system, child: Text(system));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGameSystem = value;
                if (value != 'Other') _customGameSystem = null;
              });
            },
            decoration: const InputDecoration(labelText: 'Game System'),
          ),
          if (_selectedGameSystem == 'Other') ...[
            const SizedBox(height: Spacing.md),
            TextFormField(
              initialValue: _customGameSystem,
              decoration: const InputDecoration(
                labelText: 'Custom Game System',
              ),
              onChanged: (value) => _customGameSystem = value,
              validator: (value) {
                if (_selectedGameSystem == 'Other' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter your game system';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: _isSaving ? null : _saveCampaign,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () => context.go(Routes.newSessionPath(campaignId)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fiber_manual_record,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Record New Session',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSessionButton extends StatelessWidget {
  const _AddSessionButton({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(Routes.addSessionPath(campaignId)),
      icon: const Icon(Icons.post_add),
      label: const Text('Add Session Manually'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Spacing.md),
      ),
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.book_outlined,
                title: 'Sessions',
                count: detail.sessions.length,
                onTap: () {
                  // Sessions are displayed in the Recent Sessions
                  // section below on this screen.
                },
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _QuickLinkCard(
                icon: Icons.public_outlined,
                title: 'World Database',
                subtitle: 'NPCs, Locations, Items',
                onTap: () =>
                    context.go(Routes.worldDatabasePath(detail.campaign.id)),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        _QuickLinkCard(
          icon: Icons.group_outlined,
          title: 'Players & Characters',
          count: detail.playerCount,
          onTap: () => context.go(Routes.playersPath(detail.campaign.id)),
        ),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: Spacing.iconSize,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (count != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        '$count total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = detail.sessions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail.sessions.length > 5)
              TextButton(
                onPressed: () {
                  // All sessions are shown in this section;
                  // a dedicated sessions list screen can be added later.
                },
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        if (sessions.isEmpty)
          _EmptySessionsState(campaignId: detail.campaign.id)
        else
          ...sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _SessionCard(
                session: session,
                campaignId: detail.campaign.id,
              ),
            ),
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
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: () =>
            context.go(Routes.sessionDetailPath(campaignId, session.id)),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title ??
                          'Session ${session.sessionNumber ?? '?'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      formatDate(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(sessionStatus: session.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySessionsState extends StatelessWidget {
  const _EmptySessionsState({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('No sessions yet', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.xs),
          Text(
            'Record your first session to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('Campaign not found', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => context.go(Routes.campaigns),
            child: const Text('Back to Campaigns'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text('Something went wrong', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
