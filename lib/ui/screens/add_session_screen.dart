import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../data/models/session.dart';
import '../../providers/campaign_providers.dart';
import '../../providers/repository_providers.dart';
import '../theme/spacing.dart';

/// Screen for manually adding a session (paste transcript or log-only).
class AddSessionScreen extends ConsumerStatefulWidget {
  const AddSessionScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _transcriptController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _hasTranscript = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              Text(
                'Add Session',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Session type toggle
              _SessionTypeToggle(
                hasTranscript: _hasTranscript,
                onChanged: (value) =>
                    setState(() => _hasTranscript = value),
              ),
              const SizedBox(height: Spacing.lg),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Session Title (optional)',
                  hintText: 'e.g., The Dragon\'s Lair',
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Date picker
              _DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (date) =>
                    setState(() => _selectedDate = date),
              ),
              const SizedBox(height: Spacing.md),

              // Transcript field (conditional)
              if (_hasTranscript) ...[
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  controller: _transcriptController,
                  decoration: const InputDecoration(
                    labelText: 'Transcript',
                    hintText: 'Paste your session transcript here...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 12,
                  minLines: 6,
                  validator: (value) {
                    if (_hasTranscript &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter a transcript';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'The transcript will be processed by AI to generate '
                  'summaries and extract entities.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: Spacing.xl),

              // Submit button
              FilledButton(
                onPressed: _isSubmitting ? null : _submitSession,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_hasTranscript
                        ? 'Add Session with Transcript'
                        : 'Log Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSession() async {
    if (_hasTranscript && !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final nextNum = await sessionRepo.getNextSessionNumber(
        widget.campaignId,
      );

      final title = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();

      final session = await sessionRepo.createSession(
        campaignId: widget.campaignId,
        sessionNumber: nextNum,
        title: title,
        date: _selectedDate,
      );

      if (_hasTranscript) {
        // Create transcript from pasted text
        await sessionRepo.createTranscript(
          sessionId: session.id,
          rawText: _transcriptController.text.trim(),
          whisperModel: 'manual',
        );
        // Set status to queued for AI processing
        await sessionRepo.updateSessionStatus(
          session.id,
          SessionStatus.queued,
        );
      } else {
        // Log-only session
        await sessionRepo.updateSessionStatus(
          session.id,
          SessionStatus.logged,
        );
      }

      // Invalidate providers
      ref.read(sessionsRevisionProvider.notifier).state++;

      if (mounted) {
        context.go(
          Routes.sessionDetailPath(widget.campaignId, session.id),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _SessionTypeToggle extends StatelessWidget {
  const _SessionTypeToggle({
    required this.hasTranscript,
    required this.onChanged,
  });

  final bool hasTranscript;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleCard(
            icon: Icons.note_alt_outlined,
            label: 'Log Only',
            description: 'Just record that it happened',
            isSelected: !hasTranscript,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ToggleCard(
            icon: Icons.article_outlined,
            label: 'With Transcript',
            description: 'Paste text for AI processing',
            isSelected: hasTranscript,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) onDateSelected(date);
      },
      borderRadius: BorderRadius.circular(Spacing.fieldRadius),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Session Date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
