import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/campaign_providers.dart';
import '../theme/spacing.dart';

/// New Campaign screen - form to create a new campaign.
/// Per APP_FLOW.md Flow 3: name (required), game system, description.
class NewCampaignScreen extends ConsumerStatefulWidget {
  const NewCampaignScreen({super.key});

  @override
  ConsumerState<NewCampaignScreen> createState() => _NewCampaignScreenState();
}

class _NewCampaignScreenState extends ConsumerState<NewCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _importController = TextEditingController();

  String? _selectedGameSystem;
  String? _customGameSystem;
  bool _isLoading = false;
  bool _showImportField = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _importController.dispose();
    super.dispose();
  }

  String? _getGameSystem() {
    if (_selectedGameSystem == 'Other') {
      return _customGameSystem?.trim();
    }
    return _selectedGameSystem;
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final campaignId = await ref.read(campaignEditorProvider).createCampaign(
        name: _nameController.text.trim(),
        gameSystem: _getGameSystem(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        importText: _importController.text.trim(),
      );

      if (mounted) {
        context.go(Routes.campaignPath(campaignId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create campaign: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNameField(theme),
                const SizedBox(height: Spacing.fieldSpacing),
                _buildGameSystemField(theme),
                if (_selectedGameSystem == 'Other') ...[
                  const SizedBox(height: Spacing.fieldSpacing),
                  _buildCustomGameSystemField(theme),
                ],
                const SizedBox(height: Spacing.fieldSpacing),
                _buildDescriptionField(theme),
                const SizedBox(height: Spacing.lg),
                _buildImportToggle(theme),
                if (_showImportField) ...[
                  const SizedBox(height: Spacing.fieldSpacing),
                  _buildImportField(theme),
                ],
                const SizedBox(height: Spacing.xl),
                _buildActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaign Name',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          key: const Key('newCampaign_name'),
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Enter campaign name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Campaign name is required';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildGameSystemField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game System',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        DropdownButtonFormField<String>(
          key: const Key('newCampaign_gameSystem'),
          initialValue: _selectedGameSystem,
          hint: const Text('Select game system'),
          items: gameSystems.map((system) {
            return DropdownMenuItem(value: system, child: Text(system));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGameSystem = value;
              if (value != 'Other') {
                _customGameSystem = null;
              }
            });
          },
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _buildCustomGameSystemField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Game System',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          key: const Key('newCampaign_customGameSystem'),
          initialValue: _customGameSystem,
          decoration: const InputDecoration(hintText: 'Enter your game system'),
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
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.xxs),
        Text(
          'Optional - brief overview of your campaign',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          key: const Key('newCampaign_description'),
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'A tale of heroes venturing into the unknown...',
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  Widget _buildImportToggle(ThemeData theme) {
    return InkWell(
      key: const Key('newCampaign_importToggle'),
      onTap: () => setState(() => _showImportField = !_showImportField),
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(
              _showImportField ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import existing campaign info',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    'Paste notes, character backstories, or world info to extract entities',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Text',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.xxs),
        Text(
          'Paste any existing campaign notes, character sheets, or world info',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          key: const Key('newCampaign_importText'),
          controller: _importController,
          decoration: const InputDecoration(
            hintText: 'Paste your existing notes here...',
          ),
          maxLines: 6,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.fieldRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'AI will process this text to extract NPCs, locations, and items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: Spacing.sm),
        FilledButton(
          key: const Key('newCampaign_create'),
          onPressed: _isLoading ? null : _createCampaign,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Campaign'),
        ),
      ],
    );
  }
}
