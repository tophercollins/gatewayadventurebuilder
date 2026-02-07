# TECH_STACK.md

Every package, dependency, API, and tool locked to specific versions. This eliminates ambiguity and ensures consistent builds.

---

## Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.38.x (stable) | Cross-platform UI framework |
| **Dart** | 3.10.x | Programming language |

**Why Flutter:**
- Single codebase: iOS, Android, Windows, Mac, Linux, Web
- Native performance (compiles to ARM)
- Offline-first capable
- Growing desktop adoption
- Long-term Google backing

---

## Local Database

| Package | Version | Purpose |
|---------|---------|---------|
| **sqflite** | ^2.3.x | SQLite plugin for Flutter |
| **sqflite_common_ffi** | ^2.3.x | Desktop SQLite support |
| **path_provider** | ^2.1.x | Local file paths |
| **path** | ^1.9.0 | Cross-platform file path manipulation |

**Why SQLite:**
- Relational data (campaigns → sessions → entities)
- Complex queries supported
- Battle-tested, portable
- Works offline

---

## Audio

| Package | Version | Purpose |
|---------|---------|---------|
| **record** | ^6.0.0 | Cross-platform audio recording |
| **just_audio** | ^0.10.5 | Audio playback with speed controls (0.5x-2x) |
| **just_audio_media_kit** | ^2.1.0 | Desktop audio backend for just_audio |
| **media_kit_libs_linux** | any | Linux media playback support |
| **media_kit_libs_windows_audio** | any | Windows media playback support |

**Why record:** Simple API, desktop + mobile, handles long recordings, multiple formats (WAV, AAC).

**Audio crash recovery:** Streaming flush to disk during recording. If app is force-quit, audio is recoverable up to the last flush point. Sessions get `interrupted` status with resume/finalize options.

---

## Transcription (Dual-Platform Strategy)

Platform-selected at runtime via `transcriptionServiceProvider`:

### macOS: Local Whisper (Free, Offline)

| Package | Version | Purpose |
|---------|---------|---------|
| **whisper_flutter_new** | ^1.0.1 | Flutter bindings for whisper.cpp |

- Model: `ggml-base.bin` (~150MB), downloaded from HuggingFace on first use
- Chunk duration: 30 minutes (default)
- Fully offline — no API cost
- Managed by `ModelManager` for download/storage

### Windows/Linux: Gemini Flash-Lite (Cloud)

| Package | Version | Purpose |
|---------|---------|---------|
| **google_generative_ai** | ^0.4.0 | Cloud STT via Gemini 2.0 Flash-Lite |

- Chunk duration: 2 minutes (keeps WAV inline data under ~10.6MB)
- Cost: ~$0.039/hr
- Requires Gemini API key via `EnvConfig`

### Architecture
```
transcriptionServiceProvider (Platform.isMacOS?)
  ├── YES → WhisperTranscriptionService (local, 30-min chunks)
  └── NO  → GeminiTranscriptionService (cloud, 2-min chunks)
```

`TranscriptionManager` checks each service's `preferredChunkDurationMs` and creates an `AudioChunker` with the appropriate duration. `MockTranscriptionService` is retained for tests.

---

## LLM Processing

| Service / Package | Model / Version | Cost (per 1M tokens) / Purpose |
|---------|-------|---------------------|
| **Google AI** | Gemini 1.5 Flash | $0.075 in / $0.30 out |
| **google_generative_ai** | ^0.4.0 | Dart SDK for Gemini Flash LLM integration |

**Why Gemini Flash:**
- Cheapest quality option
- 1M token context (handles long transcripts)
- Forces good prompt engineering discipline
- Easy to swap to GPT-4o or Claude later

**Abstraction:** Build a provider interface so LLM can be swapped without code changes.

---

## Backend (Sync & Auth)

| Service | Purpose |
|---------|---------|
| **Supabase** | Postgres database, Auth, Storage, Realtime |

**Why Supabase:**
- Postgres-based (industry standard, portable)
- Open source (can self-host later)
- Built-in auth
- Low lock-in risk
- Generous free tier for MVP

| Package | Version | Purpose |
|---------|---------|---------|
| **supabase_flutter** | ^2.x | Flutter client for Supabase |

---

## Email Notifications

| Service / Package | Version | Purpose |
|---------|---------|---------|
| **Resend** | — | Transactional email |
| **http** | ^1.2.0 | HTTP client for Resend email API calls |

**Why Resend:**
- Modern API
- Cheap
- Easy to swap to SendGrid/Postmark/SMTP later

---

## Image Handling

| Package | Version | Purpose |
|---------|---------|---------|
| **file_picker** | ^8.0.0 | Native OS file dialogs for image selection |
| **image** | ^4.1.0 | Pure Dart image resize/compress (no platform channels) |

**Storage:** Entity images stored locally at `{app_docs}/ttrpg_tracker/images/{entityType}/{entityId}.jpg`. Banners (campaigns) resized to max 1200px wide; avatars (all others) cropped to square and resized to max 512px. JPEG quality 85.

---

## File Storage

### Local (MVP)
- Audio files stored locally via `path_provider`
- Entity images stored locally via `path_provider` + `image` package
- SQLite for structured data
- Raw transcripts as text files or in DB

### Cloud (V2+)
- **Supabase Storage** for audio backup/sync
- Or **Cloudflare R2** (cheaper for large files)

---

## State Management (Flutter)

| Package | Version | Purpose |
|---------|---------|---------|
| **riverpod** | ^2.5.x | State management |
| **go_router** | ^14.0.0 | Declarative routing |
| **shared_preferences** | ^2.2.0 | Onboarding state persistence |
| **connectivity_plus** | ^6.0.0 | Network connectivity monitoring |
| **intl** | ^0.19.0 | Date and number formatting |

**Why Riverpod:**
- Type-safe
- Testable
- Good for complex apps
- Active development

**Decision made:** Riverpod exclusively. No bloc/provider/setState patterns.

---

## Development Tools

| Tool | Purpose |
|------|---------|
| **VS Code** or **Android Studio** | IDE |
| **Flutter DevTools** | Debugging, performance |
| **Git** | Version control |
| **GitHub Actions** | CI/CD |

---

## Platform-Specific Notes

### Desktop (Windows, Mac, Linux)
- Full offline support
- Local Whisper transcription
- SQLite for storage
- ~150-500MB app size (with Whisper model)

### Mobile (iOS, Android) - Future
- Cloud transcription default (smaller app)
- Optional model download for offline
- Push notifications via Firebase Cloud Messaging

### Web - Future (Low Priority)
- Limited audio recording support
- Cloud-only processing
- Supabase for storage

---

## Version Locking Strategy

```yaml
# Actual pubspec.yaml dependencies (v0.2.0)
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  path_provider: ^2.1.0
  record: ^6.0.0
  just_audio: ^0.10.5
  just_audio_media_kit: ^2.1.0
  media_kit_libs_linux: any
  media_kit_libs_windows_audio: any
  supabase_flutter: ^2.0.0
  google_generative_ai: ^0.4.0
  whisper_flutter_new: ^1.0.1
  uuid: ^4.0.0
  flutter_secure_storage: ^9.0.0
  path: ^1.9.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  http: ^1.2.0
  connectivity_plus: ^6.0.0
  go_router: ^14.0.0
  flutter_dotenv: ^6.0.0
```

- Use caret (^) for minor version flexibility
- Lock major versions
- Run `flutter pub upgrade --major-versions` periodically
- Test thoroughly before major upgrades

---

## API Keys & Secrets

| Service | Secret Type | Storage |
|---------|-------------|---------|
| Google AI (Gemini) | API Key | Environment variable / secure storage |
| Supabase | Anon Key + URL | Environment variable |
| Resend | API Key | Server-side only |

**Never commit API keys to git.**

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (v0.2.0)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  UI (29     │  │   State     │  │  Services   │     │
│  │  screens +  │  │ (Riverpod   │  │  (40+ files)│     │
│  │  30 widgets)│  │  19 files)  │  │             │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│         │                │                │             │
│         └────────────────┼────────────────┘             │
│                          │                              │
│  ┌───────────────────────┼───────────────────────────┐ │
│  │                 Local Layer                        │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │ │
│  │  │  SQLite  │  │  Audio   │  │   Whisper    │    │ │
│  │  │  (v3)    │  │  Files   │  │  (macOS)     │    │ │
│  │  └──────────┘  └──────────┘  └──────────────┘    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           │ (When Online)
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Cloud Services                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ Supabase │  │  Gemini  │  │  Resend  │  │ Gemini │ │
│  │  (Auth,  │  │  Flash   │  │ (Email)  │  │ Flash- │ │
│  │  Sync)   │  │  (LLM)   │  │          │  │  Lite  │ │
│  │ (future) │  │          │  │          │  │ (STT)  │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter | Single codebase, native performance, all platforms |
| Language | Dart | Comes with Flutter, easy to learn |
| Database | SQLite | Relational, offline, portable |
| Audio Recording | record ^6.0.0 | Simple, cross-platform |
| Audio Playback | just_audio + media_kit | Speed controls, desktop support |
| Transcription (macOS) | whisper_flutter_new | Local, free, offline |
| Transcription (Win/Linux) | Gemini Flash-Lite | No native whisper.cpp, reuses existing dependency |
| LLM | Gemini Flash | Cheapest, 1M token context, easy to swap later |
| Backend | Supabase | Postgres, low lock-in, can self-host |
| Email | Resend | Modern, cheap, swappable |
| State | Riverpod | Type-safe, testable |
| Routing | go_router | Declarative, deep linking support |

---

## Document References

- PRD.md - Feature requirements
- APP_FLOW.md - User navigation
- FRONTEND_GUIDELINES.md - Design system
- BACKEND_STRUCTURE.md - Database schema
- IMPLEMENTATION_PLAN.md - Build sequence
