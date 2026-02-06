import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/recording_providers.dart';
import '../../services/audio/audio_recording_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/recording_indicator.dart';

/// Recording screen with timer, stop button, and recording indicator.
/// Per APP_FLOW.md Flow 5: Recording runs until user clicks Stop.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  bool _hasInitialized = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRecording();
    });
  }

  Future<void> _initializeRecording() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final notifier = ref.read(recordingNotifierProvider.notifier);
    notifier.initialize(
      sessionId: widget.sessionId,
      campaignId: widget.campaignId,
    );

    await notifier.startRecording();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordingState = ref.watch(recordingNotifierProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Show confirmation dialog before leaving
        await _showStopConfirmation();
      },
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Spacing.maxContentWidth,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Recording indicator
                const RecordingIndicator(),
                const SizedBox(height: Spacing.xl),

                // Timer display
                _TimerDisplay(duration: recordingState.elapsedTime),
                const SizedBox(height: Spacing.lg),

                // Status text
                Text(
                  _getStatusText(recordingState.state),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xxl),

                // Control buttons
                _buildControls(theme, recordingState),

                // Error message
                if (recordingState.hasError) ...[
                  const SizedBox(height: Spacing.lg),
                  _buildErrorMessage(theme, recordingState.error!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, RecordingScreenState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button
        if (state.isRecording || state.isPaused)
          IconButton.outlined(
            onPressed: state.isPaused
                ? () => ref
                      .read(recordingNotifierProvider.notifier)
                      .resumeRecording()
                : () => ref
                      .read(recordingNotifierProvider.notifier)
                      .pauseRecording(),
            icon: Icon(
              state.isPaused ? Icons.play_arrow : Icons.pause,
              size: 32,
            ),
            iconSize: 32,
            style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
          ),

        const SizedBox(width: Spacing.xl),

        // Stop button (large, prominent)
        _StopButton(
          onPressed: _isStopping ? null : _stopRecording,
          isLoading: _isStopping,
        ),

        const SizedBox(width: Spacing.xl),

        // Cancel button (smaller, less prominent)
        if (state.isRecording || state.isPaused)
          IconButton.outlined(
            onPressed: _showCancelConfirmation,
            icon: const Icon(Icons.close, size: 32),
            iconSize: 32,
            style: IconButton.styleFrom(
              minimumSize: const Size(64, 64),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme, AudioRecordingException error) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              error.userMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(recordingNotifierProvider.notifier).clearError();
            },
            icon: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }

  String _getStatusText(RecordingState state) {
    return switch (state) {
      RecordingState.idle => 'Preparing...',
      RecordingState.recording => 'Recording in progress',
      RecordingState.paused => 'Recording paused',
      RecordingState.stopped => 'Recording stopped',
    };
  }

  Future<void> _stopRecording() async {
    setState(() => _isStopping = true);

    final notifier = ref.read(recordingNotifierProvider.notifier);
    final filePath = await notifier.stopRecording();

    if (!mounted) return;
    if (filePath != null) {
      context.go(Routes.postSessionPath(widget.campaignId, widget.sessionId));
    } else {
      setState(() => _isStopping = false);
    }
  }

  Future<bool> _showStopConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text(
          'Do you want to stop the recording and save the session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Recording'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await _stopRecording();
            },
            child: const Text('Stop and Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showCancelConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recording?'),
        content: const Text(
          'This will discard the recording. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Recording'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref.read(recordingNotifierProvider.notifier).cancelRecording();
      if (mounted) {
        context.go(Routes.campaignPath(widget.campaignId));
      }
    }
  }
}

/// Large stop button for ending the recording.
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordingColor = theme.brightness.recording;

    return Material(
      shape: const CircleBorder(),
      color: recordingColor,
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Timer display widget showing elapsed time in HH:MM:SS format.
class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Always show HH:MM:SS for timer display
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final timerText =
        '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Text(
      timerText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 2,
      ),
    );
  }
}
