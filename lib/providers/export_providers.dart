import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/export/export_service.dart';
import '../services/export/file_saver.dart';

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

/// Notifier for managing export state.
class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(const ExportState());

  void setExporting() {
    state = const ExportState(isExporting: true);
  }

  void setComplete(String filePath) {
    state = ExportState(exportedFilePath: filePath);
  }

  void setError(String error) {
    state = ExportState(error: error);
  }

  void reset() {
    state = const ExportState();
  }
}

/// Provider for export state management.
final exportStateProvider =
    StateNotifierProvider.autoDispose<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier();
});
