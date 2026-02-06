import 'package:flutter/material.dart';

import '../../services/transcription/transcript_result.dart';
import '../theme/spacing.dart';

/// A widget that displays the saving state during post-session processing.
class SavingStateIndicator extends StatelessWidget {
  const SavingStateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Saving Recording...',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Please wait while we save your session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A widget that displays transcription progress with phase-specific UI.
class TranscriptionProgressIndicator extends StatelessWidget {
  const TranscriptionProgressIndicator({
    required this.progress,
    required this.message,
    required this.phase,
    this.sessionDetailsWidget,
    super.key,
  });

  final double progress;
  final String message;
  final TranscriptionPhase phase;
  final Widget? sessionDetailsWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress indicator
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPhaseIcon(phase),
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  if (progress > 0) ...[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Title
        Text(
          'Transcribing Session',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.sm),

        // Status message
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),

        // Session details (if available)
        if (sessionDetailsWidget != null) ...[
          sessionDetailsWidget!,
          const SizedBox(height: Spacing.lg),
        ],

        // Info card
        _TranscriptionInfoCard(),
      ],
    );
  }

  IconData _getPhaseIcon(TranscriptionPhase phase) {
    return switch (phase) {
      TranscriptionPhase.preparing => Icons.hourglass_empty,
      TranscriptionPhase.chunking => Icons.content_cut,
      TranscriptionPhase.transcribing => Icons.record_voice_over,
      TranscriptionPhase.merging => Icons.merge,
      TranscriptionPhase.saving => Icons.save,
      TranscriptionPhase.complete => Icons.check_circle,
      TranscriptionPhase.error => Icons.error,
    };
  }
}

class _TranscriptionInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Transcription is running locally on your device. '
              'This may take a few minutes for longer recordings.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
