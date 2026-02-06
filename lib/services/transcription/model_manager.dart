import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'transcription_service.dart';

/// Manages whisper model download and storage for macOS local transcription.
class ModelManager {
  static const _modelDir = 'whisper_models';
  static const _baseUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main';

  /// Get the local file path for a model.
  Future<String> modelPath(String modelName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_modelDir/ggml-$modelName.bin';
  }

  /// Check if a model has been downloaded.
  Future<bool> isModelDownloaded(String modelName) async {
    final path = await modelPath(modelName);
    return File(path).existsSync();
  }

  /// Download a model from Hugging Face with progress reporting.
  Future<String> downloadModel(
    String modelName, {
    void Function(double progress)? onProgress,
  }) async {
    final path = await modelPath(modelName);
    final file = File(path);

    // Create directory if needed
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // If already downloaded, return path
    if (file.existsSync()) {
      final expectedSize = WhisperModelInfo.getByName(modelName)?.sizeBytes;
      if (expectedSize == null || file.lengthSync() > expectedSize ~/ 2) {
        onProgress?.call(1.0);
        return path;
      }
    }

    final url = '$_baseUrl/ggml-$modelName.bin';
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw TranscriptionException(
          TranscriptionErrorType.processingFailed,
          message: 'Failed to download model: HTTP ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength;
      var bytesReceived = 0;

      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          bytesReceived += chunk.length;
          if (contentLength > 0) {
            onProgress?.call(bytesReceived / contentLength);
          }
        }
      } finally {
        await sink.close();
      }

      onProgress?.call(1.0);
      return path;
    } catch (e) {
      // Clean up partial download
      if (file.existsSync()) {
        file.deleteSync();
      }
      if (e is TranscriptionException) rethrow;
      throw TranscriptionException(
        TranscriptionErrorType.processingFailed,
        message: 'Model download failed: $e',
      );
    } finally {
      client.close();
    }
  }

  /// Delete a downloaded model.
  Future<void> deleteModel(String modelName) async {
    final path = await modelPath(modelName);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// List of available models with metadata.
  List<WhisperModelInfo> get availableModels =>
      WhisperModelInfo.availableModels;
}
