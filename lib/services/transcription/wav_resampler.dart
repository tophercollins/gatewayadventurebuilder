import 'dart:io';

import 'package:flutter/foundation.dart';

/// Resamples a WAV file to 16 kHz mono for Whisper compatibility.
class WavResampler {
  static const targetSampleRate = 16000;
  static const targetChannels = 1;
  static const targetBitsPerSample = 16;

  /// Ensures a WAV file is 16 kHz mono 16-bit PCM.
  ///
  /// Returns the original path if already correct, or a new path
  /// to a resampled temporary file.
  static Future<ResampleResult> ensureWhisperFormat(
    String audioFilePath,
  ) async {
    final file = File(audioFilePath);
    final header = await _readHeader(file);

    debugPrint(
      '[WavResampler] WAV header: ${header.sampleRate}Hz, '
      '${header.numChannels}ch, ${header.bitsPerSample}bit, '
      'dataOffset=${header.dataOffset}, dataSize=${header.dataSize}',
    );

    if (header.sampleRate == targetSampleRate &&
        header.numChannels == targetChannels &&
        header.bitsPerSample == targetBitsPerSample) {
      debugPrint(
        '[WavResampler] Audio already in Whisper format, no resampling needed',
      );
      return ResampleResult(filePath: audioFilePath, isTemporary: false);
    }

    debugPrint(
      '[WavResampler] Resampling from ${header.sampleRate}Hz to ${targetSampleRate}Hz',
    );
    final outputPath = '$audioFilePath.16k.wav';
    await _resample(file, header, outputPath);

    final outputFile = File(outputPath);
    final outputSize = await outputFile.length();
    debugPrint('[WavResampler] Resampled file size: $outputSize bytes');

    return ResampleResult(filePath: outputPath, isTemporary: true);
  }

  /// Read WAV header by scanning RIFF chunks properly.
  /// Handles WAV files with extra chunks (LIST, fact, etc.).
  static Future<_WavHeader> _readHeader(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      // Read RIFF header (12 bytes)
      final riffHeader = await raf.read(12);
      if (riffHeader.length < 12) {
        throw const FormatException('WAV header too short');
      }

      final riff = String.fromCharCodes(riffHeader.sublist(0, 4));
      final wave = String.fromCharCodes(riffHeader.sublist(8, 12));
      if (riff != 'RIFF' || wave != 'WAVE') {
        throw const FormatException('Not a valid WAV file');
      }

      // Scan sub-chunks to find fmt and data
      int? numChannels;
      int? sampleRate;
      int? bitsPerSample;
      int? dataSize;
      int? dataOffset;

      final fileLength = await raf.length();
      var pos = 12;

      while (pos < fileLength - 8) {
        await raf.setPosition(pos);
        final chunkHeader = await raf.read(8);
        if (chunkHeader.length < 8) break;

        final chunkId = String.fromCharCodes(chunkHeader.sublist(0, 4));
        final bd = ByteData.sublistView(chunkHeader);
        final chunkSize = bd.getUint32(4, Endian.little);

        if (chunkId == 'fmt ') {
          final fmtSize = chunkSize.clamp(0, 40);
          final fmtData = await raf.read(fmtSize);
          if (fmtData.length >= 16) {
            final fmtBd = ByteData.sublistView(fmtData);
            numChannels = fmtBd.getUint16(2, Endian.little);
            sampleRate = fmtBd.getUint32(4, Endian.little);
            bitsPerSample = fmtBd.getUint16(14, Endian.little);
          }
        } else if (chunkId == 'data') {
          dataOffset = pos + 8;
          final actualDataSize = fileLength - dataOffset;
          // Streaming WAV recorders may write a placeholder dataSize
          // that never gets updated. Use actual file size instead.
          if (chunkSize == 0 ||
              chunkSize > actualDataSize ||
              (actualDataSize - chunkSize).abs() > 4096) {
            debugPrint(
              '[WavResampler] WARNING: data chunk size ($chunkSize) differs '
              'from actual data ($actualDataSize). Using actual file size.',
            );
          }
          dataSize = actualDataSize;
          break;
        }

        // Move to next chunk (chunks are word-aligned)
        pos += 8 + chunkSize;
        if (chunkSize % 2 != 0) pos++;
      }

      if (numChannels == null || sampleRate == null || bitsPerSample == null) {
        throw const FormatException('WAV file missing fmt chunk');
      }

      if (dataSize == null || dataOffset == null) {
        // Fallback: assume data starts at byte 44
        dataOffset = 44;
        dataSize = fileLength - 44;
        debugPrint(
          '[WavResampler] WARNING: data chunk not found, assuming offset=44',
        );
      }

      return _WavHeader(
        numChannels: numChannels,
        sampleRate: sampleRate,
        bitsPerSample: bitsPerSample,
        dataSize: dataSize,
        dataOffset: dataOffset,
      );
    } finally {
      await raf.close();
    }
  }

  static Future<void> _resample(
    File sourceFile,
    _WavHeader header,
    String outputPath,
  ) async {
    final raf = await sourceFile.open(mode: FileMode.read);
    try {
      await raf.setPosition(header.dataOffset);
      final rawData = await raf.read(header.dataSize);

      // Convert source samples to mono float64 in [-1, 1] range
      final sourceSamples = _toMonoFloat(
        rawData,
        header.numChannels,
        header.bitsPerSample,
      );

      // Resample using linear interpolation
      final ratio = header.sampleRate / targetSampleRate;
      final outputLength = (sourceSamples.length / ratio).floor();
      final resampled = Float64List(outputLength);

      for (var i = 0; i < outputLength; i++) {
        final srcPos = i * ratio;
        final srcIndex = srcPos.floor();
        final frac = srcPos - srcIndex;

        if (srcIndex + 1 < sourceSamples.length) {
          resampled[i] =
              sourceSamples[srcIndex] * (1 - frac) +
              sourceSamples[srcIndex + 1] * frac;
        } else if (srcIndex < sourceSamples.length) {
          resampled[i] = sourceSamples[srcIndex];
        }
      }

      // Convert back to 16-bit PCM
      final pcmData = _toPcm16(resampled);

      // Write output WAV
      final outputFile = File(outputPath);
      final wavHeader = _createHeader(pcmData.length);
      await outputFile.writeAsBytes([...wavHeader, ...pcmData]);
    } finally {
      await raf.close();
    }
  }

  /// Convert raw PCM bytes to mono float samples.
  static Float64List _toMonoFloat(
    Uint8List rawData,
    int numChannels,
    int bitsPerSample,
  ) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final frameSize = bytesPerSample * numChannels;
    final numFrames = rawData.length ~/ frameSize;
    final samples = Float64List(numFrames);
    final bd = ByteData.sublistView(rawData);

    for (var i = 0; i < numFrames; i++) {
      var sum = 0.0;
      for (var ch = 0; ch < numChannels; ch++) {
        final offset = i * frameSize + ch * bytesPerSample;
        if (offset + bytesPerSample > rawData.length) break;

        if (bitsPerSample == 16) {
          sum += bd.getInt16(offset, Endian.little) / 32768.0;
        } else if (bitsPerSample == 24) {
          final b0 = rawData[offset];
          final b1 = rawData[offset + 1];
          final b2 = rawData[offset + 2];
          var value = b0 | (b1 << 8) | (b2 << 16);
          if (value >= 0x800000) value -= 0x1000000;
          sum += value / 8388608.0;
        } else if (bitsPerSample == 32) {
          sum += bd.getInt32(offset, Endian.little) / 2147483648.0;
        } else {
          // 8-bit unsigned
          sum += (rawData[offset] - 128) / 128.0;
        }
      }
      samples[i] = sum / numChannels;
    }
    return samples;
  }

  /// Convert float samples to 16-bit PCM bytes.
  static Uint8List _toPcm16(Float64List samples) {
    final pcm = ByteData(samples.length * 2);
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final int16 = (clamped * 32767).round();
      pcm.setInt16(i * 2, int16, Endian.little);
    }
    return pcm.buffer.asUint8List();
  }

  /// Create a 16 kHz mono 16-bit WAV header.
  static Uint8List _createHeader(int dataSize) {
    final header = ByteData(44);
    const byteRate = targetSampleRate * targetChannels * 2;

    // RIFF
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, targetChannels, Endian.little);
    header.setUint32(24, targetSampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, targetChannels * 2, Endian.little);
    header.setUint16(34, targetBitsPerSample, Endian.little);

    // data
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }
}

class _WavHeader {
  const _WavHeader({
    required this.numChannels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataSize,
    required this.dataOffset,
  });

  final int numChannels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataSize;
  final int dataOffset;
}

/// Result of a resample operation.
class ResampleResult {
  const ResampleResult({required this.filePath, required this.isTemporary});

  final String filePath;
  final bool isTemporary;
}
