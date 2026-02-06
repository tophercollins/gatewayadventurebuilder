import 'dart:io';
import 'dart:typed_data';

import 'audio_chunker_types.dart';

export 'audio_chunker_types.dart';

/// Utility for splitting long audio files into processable chunks.
/// Handles WAV format specifically for the MVP.
class AudioChunker {
  AudioChunker({
    this.chunkDurationMs = 30 * 60 * 1000, // 30 minutes default
    this.overlapMs = 5000, // 5 second overlap for context
  });

  /// Target duration for each chunk in milliseconds.
  final int chunkDurationMs;

  /// Overlap between chunks in milliseconds (for better transcription).
  final int overlapMs;

  /// List of temporary files created (for cleanup).
  final List<String> _temporaryFiles = [];

  /// Split an audio file into chunks if needed.
  /// Returns list of chunks with metadata for timestamp adjustment.
  ///
  /// For short files, returns a single "chunk" pointing to the original file.
  /// For long files, creates temporary chunk files.
  Future<List<AudioChunk>> splitIfNeeded(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw AudioChunkerException(
        AudioChunkerError.fileNotFound,
        message: 'Audio file not found: $audioFilePath',
      );
    }

    // Try to read WAV header, but fallback to simple estimation if it fails
    WavInfo wavInfo;
    try {
      wavInfo = await _readWavInfo(file);
    } catch (e) {
      // Fallback: estimate based on file size (assume 44.1kHz, 16-bit, mono WAV)
      final fileSize = await file.length();
      // Assume 16kHz, 16-bit, mono WAV (32000 bytes/sec)
      final estimatedDurationMs = ((fileSize - 44) / 32000 * 1000).round();
      wavInfo = WavInfo(
        numChannels: 1,
        sampleRate: 16000,
        bitsPerSample: 16,
        dataSize: fileSize - 44,
        durationMs: estimatedDurationMs > 0 ? estimatedDurationMs : 60000,
        headerSize: 44,
      );
    }
    final totalDurationMs = wavInfo.durationMs;

    // If audio is shorter than chunk duration, return single chunk
    if (totalDurationMs <= chunkDurationMs) {
      return [
        AudioChunk(
          filePath: audioFilePath,
          chunkIndex: 0,
          totalChunks: 1,
          startTimeMs: 0,
          endTimeMs: totalDurationMs,
          isTemporary: false,
        ),
      ];
    }

    // Calculate number of chunks needed
    final effectiveChunkDuration = chunkDurationMs - overlapMs;
    final numChunks = ((totalDurationMs - overlapMs) / effectiveChunkDuration)
        .ceil();

    final chunks = <AudioChunk>[];

    for (var i = 0; i < numChunks; i++) {
      final startTimeMs = i * effectiveChunkDuration;
      final endTimeMs = (startTimeMs + chunkDurationMs).clamp(
        0,
        totalDurationMs,
      );

      // Create chunk file
      final chunkPath = await _createChunkFile(
        file,
        wavInfo,
        startTimeMs,
        endTimeMs,
        i,
      );

      chunks.add(
        AudioChunk(
          filePath: chunkPath,
          chunkIndex: i,
          totalChunks: numChunks,
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs,
          isTemporary: true,
        ),
      );
    }

    return chunks;
  }

  /// Clean up any temporary chunk files created.
  Future<void> cleanup() async {
    for (final path in _temporaryFiles) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
    _temporaryFiles.clear();
  }

  /// Read WAV file header information.
  Future<WavInfo> _readWavInfo(File file) async {
    final bytes = await file.openRead(0, 44).toList();
    if (bytes.isEmpty) {
      throw const AudioChunkerException(
        AudioChunkerError.invalidFormat,
        message: 'Could not read WAV header',
      );
    }

    final header = bytes.expand((e) => e).toList();
    if (header.length < 44) {
      throw const AudioChunkerException(
        AudioChunkerError.invalidFormat,
        message: 'WAV header too short',
      );
    }

    // Verify RIFF header
    final riff = String.fromCharCodes(header.sublist(0, 4));
    if (riff != 'RIFF') {
      throw const AudioChunkerException(
        AudioChunkerError.invalidFormat,
        message: 'Not a valid WAV file (missing RIFF header)',
      );
    }

    // Verify WAVE format
    final wave = String.fromCharCodes(header.sublist(8, 12));
    if (wave != 'WAVE') {
      throw const AudioChunkerException(
        AudioChunkerError.invalidFormat,
        message: 'Not a valid WAV file (missing WAVE format)',
      );
    }

    // Parse format chunk
    final numChannels = _readInt16LE(header, 22);
    final sampleRate = _readInt32LE(header, 24);
    final bitsPerSample = _readInt16LE(header, 34);

    // Calculate data size and duration
    final fileSize = await file.length();
    final dataSize = fileSize - 44; // Approximate, assumes simple WAV
    final bytesPerSample = (bitsPerSample / 8).ceil();
    final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
    final durationMs = ((totalSamples / sampleRate) * 1000).round();

    return WavInfo(
      numChannels: numChannels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataSize: dataSize,
      durationMs: durationMs,
      headerSize: 44,
    );
  }

  /// Create a chunk file from the source audio.
  Future<String> _createChunkFile(
    File sourceFile,
    WavInfo wavInfo,
    int startTimeMs,
    int endTimeMs,
    int chunkIndex,
  ) async {
    final bytesPerSecond =
        wavInfo.sampleRate * wavInfo.numChannels * (wavInfo.bitsPerSample ~/ 8);
    final startByte =
        wavInfo.headerSize + ((startTimeMs / 1000) * bytesPerSecond).round();
    final endByte =
        wavInfo.headerSize + ((endTimeMs / 1000) * bytesPerSecond).round();
    final chunkDataSize = endByte - startByte;

    // Create temporary file
    final chunkPath = '${sourceFile.path}.chunk_$chunkIndex.wav';
    final chunkFile = File(chunkPath);

    // Write WAV header for chunk
    final chunkHeader = _createWavHeader(
      chunkDataSize,
      wavInfo.sampleRate,
      wavInfo.numChannels,
      wavInfo.bitsPerSample,
    );

    // Read only the needed byte range using RandomAccessFile (streaming)
    final raf = await sourceFile.open(mode: FileMode.read);
    try {
      final fileLength = await raf.length();
      final clampedStart = startByte.clamp(0, fileLength);
      final clampedEnd = endByte.clamp(0, fileLength);
      final readLength = clampedEnd - clampedStart;

      await raf.setPosition(clampedStart);
      final audioData = await raf.read(readLength);

      // Write chunk file
      await chunkFile.writeAsBytes([...chunkHeader, ...audioData]);
    } finally {
      await raf.close();
    }

    _temporaryFiles.add(chunkPath);
    return chunkPath;
  }

  /// Create a WAV file header.
  Uint8List _createWavHeader(
    int dataSize,
    int sampleRate,
    int numChannels,
    int bitsPerSample,
  ) {
    final header = ByteData(44);
    final bytesPerSample = bitsPerSample ~/ 8;
    final byteRate = sampleRate * numChannels * bytesPerSample;

    // RIFF chunk
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little); // File size - 8
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // Chunk size
    header.setUint16(20, 1, Endian.little); // Audio format (PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, numChannels * bytesPerSample, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  int _readInt16LE(List<int> bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readInt32LE(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
