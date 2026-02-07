import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/playback_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import 'speed_control_button.dart';

/// Card displaying audio playback controls for a session.
///
/// Shows play/pause, seek bar, skip controls, speed selector,
/// and current/total time. Matches the SectionCard visual style.
class AudioPlayerCard extends ConsumerStatefulWidget {
  const AudioPlayerCard({
    required this.sessionId,
    required this.audioInfo,
    super.key,
  });

  final String sessionId;
  final SessionAudioInfo audioInfo;

  @override
  ConsumerState<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends ConsumerState<AudioPlayerCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playback = ref.watch(playbackNotifierProvider);

    // Auto-load audio when the notifier is freshly created (idle).
    // loadSession transitions to PlaybackStatus.loading immediately,
    // so the idle guard prevents re-triggering on subsequent rebuilds.
    if (playback.status == PlaybackStatus.idle && widget.audioInfo.fileExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(playbackNotifierProvider.notifier)
              .loadSession(widget.audioInfo.filePath, widget.sessionId);
        }
      });
    }

    if (!widget.audioInfo.fileExists) {
      return _buildFileNotFoundCard(theme);
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, playback),
          const SizedBox(height: Spacing.md),
          _buildSeekBar(theme, playback),
          const SizedBox(height: Spacing.xs),
          _buildTimeRow(theme, playback),
          const SizedBox(height: Spacing.sm),
          _buildControls(theme, playback),
          if (playback.status == PlaybackStatus.error &&
              playback.error != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              playback.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, PlaybackState playback) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Icon(
            Icons.headphones_outlined,
            color: theme.colorScheme.primary,
            size: Spacing.iconSizeCompact,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            'Session Audio',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SpeedControlButton(
          currentSpeed: playback.speed,
          onSpeedChanged: (speed) {
            ref.read(playbackNotifierProvider.notifier).setSpeed(speed);
          },
        ),
      ],
    );
  }

  Widget _buildSeekBar(ThemeData theme, PlaybackState playback) {
    final max = playback.duration.inMilliseconds.toDouble();
    final value = playback.position.inMilliseconds.toDouble().clamp(0.0, max);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        value: max > 0 ? value : 0,
        max: max > 0 ? max : 1,
        activeColor: theme.colorScheme.primary,
        inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        onChanged: playback.isLoaded
            ? (ms) {
                ref
                    .read(playbackNotifierProvider.notifier)
                    .seek(Duration(milliseconds: ms.round()));
              }
            : null,
      ),
    );
  }

  Widget _buildTimeRow(ThemeData theme, PlaybackState playback) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formatDuration(playback.position),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            formatDuration(playback.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme, PlaybackState playback) {
    final isLoaded = playback.isLoaded;
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: Spacing.iconSizeLarge,
          color: theme.colorScheme.onSurfaceVariant,
          tooltip: 'Skip back 10 seconds',
          onPressed: isLoaded
              ? () => notifier.skipBackward(const Duration(seconds: 10))
              : null,
        ),
        const SizedBox(width: Spacing.md),
        FilledButton(
          onPressed: isLoaded ? notifier.playPause : null,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(Spacing.md),
          ),
          child: Icon(
            playback.isPlaying ? Icons.pause : Icons.play_arrow,
            size: Spacing.iconSizeLarge,
          ),
        ),
        const SizedBox(width: Spacing.md),
        IconButton(
          icon: const Icon(Icons.forward_30),
          iconSize: Spacing.iconSizeLarge,
          color: theme.colorScheme.onSurfaceVariant,
          tooltip: 'Skip forward 30 seconds',
          onPressed: isLoaded
              ? () => notifier.skipForward(const Duration(seconds: 30))
              : null,
        ),
      ],
    );
  }

  Widget _buildFileNotFoundCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: Spacing.iconSizeCompact,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Audio file not found on disk',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
