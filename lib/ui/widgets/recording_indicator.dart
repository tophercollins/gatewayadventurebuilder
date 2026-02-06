import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../theme/colors.dart';

/// Recording indicator with pulsing red dot.
/// Per FRONTEND_GUIDELINES.md: 1s cycle pulsing animation.
class RecordingIndicator extends StatefulWidget {
  const RecordingIndicator({this.size = 24, this.showLabel = true, super.key});

  final double size;
  final bool showLabel;

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1 second cycle per FRONTEND_GUIDELINES.md
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Pulse from 0.4 to 1.0 opacity
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Repeat the animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordingColor = theme.brightness.recording;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing dot
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordingColor.withValues(alpha: _animation.value),
                boxShadow: [
                  BoxShadow(
                    color: recordingColor.withValues(
                      alpha: _animation.value * 0.5,
                    ),
                    blurRadius: widget.size / 2,
                    spreadRadius: widget.size / 8,
                  ),
                ],
              ),
            );
          },
        ),

        // Label
        if (widget.showLabel) ...[
          const SizedBox(width: 12),
          Text(
            'REC',
            style: theme.textTheme.titleMedium?.copyWith(
              color: recordingColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact recording indicator for app bar or status bar.
class CompactRecordingIndicator extends StatelessWidget {
  const CompactRecordingIndicator({this.duration, super.key});

  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecordingIndicator(size: 12, showLabel: false),
          if (duration != null) ...[
            const SizedBox(width: 8),
            Text(
              formatDuration(duration!),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
