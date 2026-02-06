/// Utility formatters for consistent display across the app.
///
/// Provides centralized formatting for durations, dates, and file sizes
/// to avoid duplicated formatting logic in UI components.
library;

/// Formats a [Duration] as HH:MM:SS for timer displays.
///
/// Shows hours only if > 0, always shows minutes and seconds.
/// Uses padded format with tabular figures for consistent width.
///
/// Examples:
/// - Duration(hours: 1, minutes: 5, seconds: 30) -> "01:05:30"
/// - Duration(minutes: 5, seconds: 30) -> "05:30"
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Formats a [Duration] in human-readable format with units.
///
/// Returns a compact representation like "1h 5m 30s" or "5m 30s".
/// Omits leading units when they are zero.
///
/// Examples:
/// - Duration(hours: 2, minutes: 30, seconds: 15) -> "2h 30m 15s"
/// - Duration(minutes: 5, seconds: 30) -> "5m 30s"
/// - Duration(seconds: 45) -> "45s"
String formatDurationHuman(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

/// Formats seconds as a human-readable duration.
///
/// Convenience wrapper around [formatDurationHuman] for use with
/// integer seconds values.
///
/// Examples:
/// - 3661 -> "1h 1m 1s"
/// - 125 -> "2m 5s"
/// - 45 -> "45s"
String formatDurationSeconds(int seconds) {
  return formatDurationHuman(Duration(seconds: seconds));
}

/// Formats a [DateTime] as "Mon DD, YYYY".
///
/// Uses abbreviated month names for compact display.
///
/// Examples:
/// - DateTime(2024, 1, 15) -> "Jan 15, 2024"
/// - DateTime(2024, 12, 31) -> "Dec 31, 2024"
String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Formats bytes as a human-readable file size.
///
/// Automatically selects appropriate unit (B, KB, MB, GB) based on size.
/// Uses 1 decimal place for KB/MB and 2 for GB.
///
/// Examples:
/// - 512 -> "512 B"
/// - 1536 -> "1.5 KB"
/// - 1572864 -> "1.5 MB"
/// - 1610612736 -> "1.50 GB"
String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
