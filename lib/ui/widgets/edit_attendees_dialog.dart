import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/campaign_providers.dart';
import '../../providers/recording_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_detail_providers.dart';
import 'attendee_selection_list.dart';

/// Dialog for editing session attendees.
/// Loads current attendees, lets user modify via AttendeeSelectionList,
/// then atomically replaces attendees on save.
class EditAttendeesDialog extends ConsumerStatefulWidget {
  const EditAttendeesDialog({
    required this.sessionId,
    required this.campaignId,
    super.key,
  });

  final String sessionId;
  final String campaignId;

  @override
  ConsumerState<EditAttendeesDialog> createState() =>
      _EditAttendeesDialogState();
}

class _EditAttendeesDialogState extends ConsumerState<EditAttendeesDialog> {
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromExisting();
    });
  }

  Future<void> _initializeFromExisting() async {
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final attendees = await sessionRepo.getAttendeesBySession(
      widget.sessionId,
    );
    final mapped = attendees
        .map((a) => (playerId: a.playerId, characterId: a.characterId))
        .toList();
    ref.read(attendeeSelectionProvider.notifier).initializeFrom(mapped);
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Attendees'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _initialized
            ? SingleChildScrollView(
                child: AttendeeSelectionList(
                  campaignId: widget.campaignId,
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final notifier = ref.read(attendeeSelectionProvider.notifier);
      final attendees = notifier.getSelectedAttendees();

      await sessionRepo.replaceAttendees(
        sessionId: widget.sessionId,
        attendees: attendees,
      );

      // Invalidate providers to refresh UI
      ref.invalidate(sessionAttendeesProvider(widget.sessionId));
      ref.read(sessionsRevisionProvider.notifier).state++;

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendees: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
