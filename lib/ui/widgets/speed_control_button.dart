import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Popup menu button displaying the current playback speed as a chip label.
/// Options: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x with checkmark on active.
class SpeedControlButton extends StatelessWidget {
  const SpeedControlButton({
    required this.currentSpeed,
    required this.onSpeedChanged,
    super.key,
  });

  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<double>(
      onSelected: onSpeedChanged,
      tooltip: 'Playback speed',
      itemBuilder: (_) => _speeds.map((speed) {
        final isActive = (speed - currentSpeed).abs() < 0.01;
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              SizedBox(
                width: Spacing.iconSize,
                child: isActive
                    ? Icon(
                        Icons.check,
                        size: Spacing.iconSizeCompact,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: Spacing.sm),
              Text('${speed}x'),
            ],
          ),
        );
      }).toList(),
      child: Chip(
        label: Text(
          '${currentSpeed}x',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        side: BorderSide(color: theme.colorScheme.outline),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
