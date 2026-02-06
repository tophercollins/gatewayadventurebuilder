import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/export/export_service.dart';
import '../services/export/file_saver.dart';
import 'processing_providers.dart';
import 'repository_providers.dart';

/// Provider for ExportService.
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Provider for FileSaver.
final fileSaverProvider = Provider<FileSaver>((ref) {
  return FileSaver();
});

/// State for tracking an in-progress export.
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.exportedFilePath,
    this.error,
  });

  final bool isExporting;
  final String? exportedFilePath;
  final String? error;
}

/// Notifier for managing export operations.
/// Orchestrates repo access, export formatting, and file saving.
class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier(this._exportService, this._fileSaver, this._ref)
      : super(const ExportState());

  final ExportService _exportService;
  final FileSaver _fileSaver;
  final Ref _ref;

  /// Exports a session in the given format and saves to disk.
  Future<void> exportSession({
    required String sessionId,
    required String format,
  }) async {
    state = const ExportState(isExporting: true);

    try {
      final sessionRepo = _ref.read(sessionRepositoryProvider);
      final summaryRepo = _ref.read(summaryRepositoryProvider);
      final actionItemRepo = _ref.read(actionItemRepositoryProvider);
      final entityRepo = _ref.read(entityRepositoryProvider);
      final campaignRepo = _ref.read(campaignRepositoryProvider);

      final String content;
      final String extension;

      if (format == 'markdown') {
        content = await _exportService.exportSessionMarkdown(
          sessionId: sessionId,
          sessionRepo: sessionRepo,
          summaryRepo: summaryRepo,
          actionItemRepo: actionItemRepo,
          entityRepo: entityRepo,
          campaignRepo: campaignRepo,
        );
        extension = 'md';
      } else {
        content = await _exportService.exportSessionJson(
          sessionId: sessionId,
          sessionRepo: sessionRepo,
          summaryRepo: summaryRepo,
          actionItemRepo: actionItemRepo,
          entityRepo: entityRepo,
          campaignRepo: campaignRepo,
        );
        extension = 'json';
      }

      final filePath = await _fileSaver.saveExportFile(
        content: content,
        suggestedFileName: 'session_$sessionId',
        fileExtension: extension,
      );

      if (!mounted) return;

      if (filePath != null) {
        state = ExportState(exportedFilePath: filePath);
      } else {
        state = const ExportState(error: 'Failed to save export file');
      }
    } catch (e) {
      if (mounted) state = ExportState(error: 'Export failed: $e');
    }
  }

  void reset() {
    state = const ExportState();
  }
}

/// Provider for export state management.
final exportStateProvider =
    StateNotifierProvider.autoDispose<ExportStateNotifier, ExportState>((ref) {
  final exportService = ref.watch(exportServiceProvider);
  final fileSaver = ref.watch(fileSaverProvider);
  return ExportStateNotifier(exportService, fileSaver, ref);
});
