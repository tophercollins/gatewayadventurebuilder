import 'package:flutter/material.dart';

import '../../data/models/session.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import 'detail_item.dart';

/// A card displaying session details like number, date, duration, and file size.
class SessionDetailsCard extends StatelessWidget {
  const SessionDetailsCard({
    required this.session,
    this.audioDurationSeconds,
    this.audioFileSizeBytes,
    super.key,
  });

  final Session? session;
  final int? audioDurationSeconds;
  final int? audioFileSizeBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session ${session?.sessionNumber ?? '?'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatDate(session?.date ?? DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: DetailItem(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: formatDurationSeconds(audioDurationSeconds ?? 0),
                ),
              ),
              Expanded(
                child: DetailItem(
                  icon: Icons.audio_file_outlined,
                  label: 'File Size',
                  value: formatFileSize(audioFileSizeBytes ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
