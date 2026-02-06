# Changelog

All notable changes to this project will be documented in this file.

---

## [0.1.0] — 2026-02-06 — Real Transcription (Dual-Strategy)

Replaces `MockTranscriptionService` with real transcription using a platform-based dual strategy:
- **macOS**: `whisper_flutter_new` — free, local, offline via whisper.cpp
- **Windows/Linux**: Gemini Flash-Lite — cloud STT at ~$0.039/hr via `google_generative_ai` (already a dependency)

### Added

#### New Files

- **`lib/services/transcription/whisper_transcription_service.dart`** (189 lines)
  - `WhisperTranscriptionService` class implementing `TranscriptionService`
  - Constructor accepts optional `whisperModel` name (default `'base'`) and `ModelManager`
  - `_whisperModelEnum` getter maps string model names (`'tiny'`, `'base'`, `'small'`, `'medium'`) to `WhisperModel` enum values
  - `isReady()` delegates to `ModelManager.isModelDownloaded()`
  - `initialize()` triggers model download if not present
  - `initializeWithProgress()` — extra method for download progress reporting
  - `transcribe()` creates a `Whisper` instance (cached via `??=`), calls `whisper.transcribe()` with `TranscribeRequest`, parses `WhisperTranscribeSegment.fromTs`/`toTs` (Duration objects) into `TranscriptSegmentData`
  - Handles nullable `result.segments` list (null when `isNoTimestamps: true`)
  - Falls back to `result.text` if segments list is empty
  - `preferredChunkDurationMs` returns `null` (uses default 30-min chunks)
  - `modelName` returns `'whisper-base'` (or whichever model is configured)
  - Reports progress via `TranscriptionProgress` callbacks at preparing/transcribing/complete phases
  - Cancellation support via `_isCancelled` flag checked between operations
  - `dispose()` nulls the `_whisper` instance

- **`lib/services/transcription/gemini_transcription_service.dart`** (202 lines)
  - `GeminiTranscriptionService` class implementing `TranscriptionService`
  - `isReady()` checks `EnvConfig.getGeminiApiKey()` is non-null and non-empty
  - `initialize()` throws `TranscriptionException(modelNotLoaded)` if no API key
  - `transcribe()`:
    - Reads WAV file bytes via `file.readAsBytes()`
    - Creates `GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: key)`
    - Sends `Content.multi([DataPart('audio/wav', bytes), TextPart(prompt)])`
    - Prompt requests JSON: `{"segments": [{"text": "...", "startMs": 0, "endMs": 5000}, ...]}`
  - `_parseResponse()`:
    - Strips markdown code fences (` ```json ... ``` `) if Gemini wraps the response
    - Parses JSON, maps `startMs`/`endMs` to `TranscriptSegmentData`
    - Throws `TranscriptionException` with `details: responseText` on parse failure
  - `preferredChunkDurationMs` returns `120000` (2 minutes — keeps WAV inline data under ~10.6MB)
  - `modelName` returns `'gemini-flash-lite'`
  - `modelSizeBytes` returns `null` (cloud service)
  - Cancellation support via `_isCancelled` flag

- **`lib/services/transcription/model_manager.dart`** (107 lines)
  - `ModelManager` class for whisper model download/storage
  - `modelPath(name)` returns `<app_documents>/whisper_models/ggml-<name>.bin`
  - `isModelDownloaded(name)` checks file existence via `File.existsSync()`
  - `downloadModel(name, {onProgress})`:
    - Creates directory recursively if missing
    - Skips download if file exists and is >50% of expected size (partial download guard)
    - Downloads from `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-<name>.bin`
    - Uses `HttpClient` with streaming writes via `file.openWrite()`
    - Reports download progress as `bytesReceived / contentLength`
    - Cleans up partial downloads on error (deletes file)
    - Throws `TranscriptionException(processingFailed)` on HTTP errors or download failures
  - `deleteModel(name)` removes the model file
  - `availableModels` getter returns `WhisperModelInfo.availableModels`

#### New Dependency

- **`pubspec.yaml`**: Added `whisper_flutter_new: ^1.0.1` under `# Local Transcription (macOS)` section
  - Transitively adds `freezed_annotation: 3.1.0` and `json_annotation: 4.10.0`

#### New Interface Member

- **`lib/services/transcription/transcription_service.dart`** line 50-53:
  - Added `int? get preferredChunkDurationMs => null;` to `abstract class TranscriptionService`
  - Default implementation returns `null` (use default 30-min chunks)
  - Doc comment explains Gemini needs shorter chunks (~2 min) for inline data limits

### Changed

#### Provider Swap — `lib/providers/transcription_providers.dart`

**Before:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...

/// Provider for the TranscriptionService (mock for MVP).
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final service = MockTranscriptionService(
    simulateDelay: true,
    delayFactor: 0.05,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
```

**After:**
```dart
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...

/// Provider for the TranscriptionService.
/// macOS: local Whisper (free, offline).
/// Windows/Linux: Gemini Flash-Lite (cloud).
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final TranscriptionService service;
  if (Platform.isMacOS) {
    service = WhisperTranscriptionService();
  } else {
    service = GeminiTranscriptionService();
  }
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
```

**What changed:**
- Added `import 'dart:io' show Platform;`
- Replaced `MockTranscriptionService(simulateDelay: true, delayFactor: 0.05)` with platform check
- macOS → `WhisperTranscriptionService()`, everything else → `GeminiTranscriptionService()`
- Updated doc comment from "mock for MVP" to describe platform strategy
- Removed blank lines between `ref.onDispose` and `return`

#### Chunk Duration Override — `lib/services/transcription/transcription_manager.dart`

**Before** (line 110):
```dart
final chunks = await audioChunker.splitIfNeeded(audioFilePath);
```

**After** (lines 110-115):
```dart
// Use service's preferred chunk duration if specified
final preferredDuration = transcriptionService.preferredChunkDurationMs;
final chunker = preferredDuration != null
    ? AudioChunker(chunkDurationMs: preferredDuration)
    : audioChunker;
final chunks = await chunker.splitIfNeeded(audioFilePath);
```

**What changed:**
- Checks `transcriptionService.preferredChunkDurationMs` before chunking
- If non-null (e.g. Gemini's 120000ms), creates a new `AudioChunker` with that duration
- If null (Whisper, Mock), uses the existing `audioChunker` instance (default 30-min)
- This is how Gemini gets 2-minute chunks while Whisper keeps 30-minute chunks

#### Mock Service Update — `lib/services/transcription/mock_transcription_service.dart`

**Added** after line 27 (`int? get modelSizeBytes => 0;`):
```dart
@override
int? get preferredChunkDurationMs => null;
```

**Why:** `MockTranscriptionService` uses `implements` (not `extends`), so it must provide all members from the interface. Returns `null` to use default chunk duration.

#### Barrel File — `lib/services/transcription/transcription.dart`

**Before:**
```dart
export 'audio_chunker.dart';
export 'mock_transcription_service.dart';
export 'transcript_result.dart';
export 'transcription_manager.dart';
export 'transcription_service.dart';
```

**After:**
```dart
export 'audio_chunker.dart';
export 'gemini_transcription_service.dart';
export 'mock_transcription_service.dart';
export 'model_manager.dart';
export 'transcript_result.dart';
export 'transcription_manager.dart';
export 'transcription_service.dart';
export 'whisper_transcription_service.dart';
```

**Added 3 exports:** `gemini_transcription_service.dart`, `model_manager.dart`, `whisper_transcription_service.dart`

#### Audio Chunker Optimization — `lib/services/transcription/audio_chunker.dart`

**Before** (lines 208-216):
```dart
// Read audio data for this chunk
final sourceBytes = await sourceFile.readAsBytes();
final audioData = sourceBytes.sublist(
  startByte.clamp(0, sourceBytes.length),
  endByte.clamp(0, sourceBytes.length),
);

// Write chunk file
await chunkFile.writeAsBytes([...chunkHeader, ...audioData]);
```

**After** (lines 211-226):
```dart
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
```

**What changed:**
- Old code read entire file into memory (`readAsBytes()`) then sliced — problematic for 10+ hour recordings
- New code uses `RandomAccessFile` to seek and read only the needed byte range
- Wrapped in try/finally to ensure `raf.close()` is always called
- No functional change to output, only memory efficiency improvement

### Not Changed

- **`lib/ui/screens/recording_screen.dart`** — No changes needed. Transcription UX messages are shown in `post_session_screen.dart` via the `TranscriptionState.message` field, which receives platform-specific text from each service's progress callbacks:
  - Whisper: `"Transcribing locally with Whisper..."`
  - Gemini: `"Transcribing via Gemini..."`
- **`lib/services/transcription/transcript_result.dart`** — Unchanged
- **`lib/ui/screens/post_session_screen.dart`** — Unchanged (already displays `state.message`)
- **`lib/config/env_config.dart`** — Unchanged (already has `getGeminiApiKey()`)
- **`MockTranscriptionService`** — Kept for tests, only added `preferredChunkDurationMs` getter

### Architecture

```
transcription_providers.dart
  └── transcriptionServiceProvider (Platform.isMacOS?)
        ├── YES → WhisperTranscriptionService
        │         ├── whisper_flutter_new (local whisper.cpp)
        │         ├── ModelManager (downloads ggml-base.bin ~150MB from HuggingFace)
        │         └── preferredChunkDurationMs: null → 30-min chunks
        └── NO  → GeminiTranscriptionService
                  ├── google_generative_ai (gemini-2.0-flash-lite)
                  ├── EnvConfig.getGeminiApiKey()
                  └── preferredChunkDurationMs: 120000 → 2-min chunks
  └── transcriptionManagerProvider
        └── TranscriptionManager
              ├── Checks service.preferredChunkDurationMs
              ├── Creates AudioChunker with preferred duration if non-null
              └── Otherwise uses default AudioChunker (30-min)
```

### Verification Results

- `flutter pub get` — success (added `whisper_flutter_new 1.0.1`, `freezed_annotation 3.1.0`, `json_annotation 4.10.0`)
- `flutter analyze` — 0 issues
- `flutter test` — 15/15 tests pass
