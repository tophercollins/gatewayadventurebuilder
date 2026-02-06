import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Utility for saving export content to a file on the local filesystem.
///
/// Files are written to `Documents/HistoryCheck/exports/` by default.
class FileSaver {
  /// Saves [content] to a file with the given [suggestedFileName] and
  /// [fileExtension].
  ///
  /// Returns the absolute file path on success, or `null` if the write
  /// fails.
  Future<String?> saveExportFile({
    required String content,
    required String suggestedFileName,
    required String fileExtension,
  }) async {
    try {
      final dir = await _getExportDirectory();
      final sanitized = _sanitizeFileName(suggestedFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${sanitized}_$timestamp.$fileExtension';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Returns the export directory, creating it if it does not exist.
  Future<Directory> _getExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${documentsDir.path}/HistoryCheck/exports',
    );
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Removes characters that are unsafe for file names.
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
