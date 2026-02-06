import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/session_transcript.dart';
import '../../data/models/transcript_segment.dart';
import '../../providers/repository_providers.dart';
import '../../providers/transcription_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/empty_state.dart';

/// Session Transcript drill-down screen.
/// Displays the full transcript with timestamped segments.
/// Allows editing the raw transcript text.
class SessionTranscriptScreen extends ConsumerWidget {
  const SessionTranscriptScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcriptAsync = ref.watch(sessionTranscriptProvider(sessionId));

    return transcriptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (transcript) {
        if (transcript == null) {
          return const NotFoundState(message: 'No transcript available');
        }
        return _TranscriptContent(
          sessionId: sessionId,
          transcript: transcript,
        );
      },
    );
  }
}

class _TranscriptContent extends ConsumerWidget {
  const _TranscriptContent({
    required this.sessionId,
    required this.transcript,
  });

  final String sessionId;
  final SessionTranscript transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentsAsync = ref.watch(
      transcriptSegmentsProvider(transcript.id),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: segmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(error: error.toString()),
          data: (segments) => _TranscriptView(
            sessionId: sessionId,
            transcript: transcript,
            segments: segments,
          ),
        ),
      ),
    );
  }
}

class _TranscriptView extends ConsumerStatefulWidget {
  const _TranscriptView({
    required this.sessionId,
    required this.transcript,
    required this.segments,
  });

  final String sessionId;
  final SessionTranscript transcript;
  final List<TranscriptSegment> segments;

  @override
  ConsumerState<_TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends ConsumerState<_TranscriptView> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(
      text: widget.transcript.displayText,
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        // Header with metadata and edit toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Transcript',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.transcript.isEdited)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.xs),
                child: Chip(
                  label: Text('edited', style: theme.textTheme.labelSmall),
                  visualDensity: VisualDensity.compact,
                  deleteIcon: const Icon(Icons.restore, size: 16),
                  onDeleted: _revertToOriginal,
                  deleteButtonTooltipMessage: 'Revert to original',
                ),
              ),
            if (widget.transcript.whisperModel != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: Chip(
                  label: Text(
                    widget.transcript.whisperModel!,
                    style: theme.textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            IconButton(
              onPressed: _toggleEdit,
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              tooltip: _isEditing ? 'Cancel editing' : 'Edit transcript',
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),

        if (_isEditing)
          _buildEditView(theme)
        else if (widget.segments.isNotEmpty)
          _buildSegmentView(theme)
        else
          _buildRawTextView(theme),
      ],
    );
  }

  Widget _buildSegmentView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.segments.length} segments',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...widget.segments.map(
          (seg) => _SegmentTile(segment: seg),
        ),
      ],
    );
  }

  Widget _buildRawTextView(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: SelectableText(
        widget.transcript.displayText,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildEditView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: TextField(
            controller: _editController,
            maxLines: null,
            minLines: 10,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            decoration: const InputDecoration.collapsed(
              hintText: 'Transcript text...',
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _toggleEdit,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: Spacing.sm),
            FilledButton(
              onPressed: _saveEdit,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        _editController.text = widget.transcript.displayText;
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveEdit() async {
    final newText = _editController.text.trim();
    if (newText == widget.transcript.displayText) {
      setState(() => _isEditing = false);
      return;
    }

    final sessionRepo = ref.read(sessionRepositoryProvider);
    await sessionRepo.updateTranscriptText(widget.transcript.id, newText);

    if (!mounted) return;

    ref.invalidate(sessionTranscriptProvider(widget.sessionId));
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcript saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _revertToOriginal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert to Original?'),
        content: const Text(
          'This will discard your edits and restore the original '
          'transcription. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final sessionRepo = ref.read(sessionRepositoryProvider);
    await sessionRepo.revertTranscriptText(widget.transcript.id);

    ref.invalidate(sessionTranscriptProvider(widget.sessionId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reverted to original transcript'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({required this.segment});

  final TranscriptSegment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = formatDuration(
      Duration(milliseconds: segment.startTimeMs),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              timestamp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: SelectableText(
              segment.text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
