# TODO - Future Features

## Completed Features (v0.2.0)

- [x] Audio Crash Recovery (Streaming Save)
- [x] Reactive State (Dynamic Pages)
- [x] Manual Session Add (Paste Transcript / Log-Only)
- [x] Home Page Redesign
- [x] Stats Dashboard (Campaign + Player + Global)
- [x] Email API (Resend Integration)
- [x] AI Podcast Summary
- [x] Export (Markdown / JSON / CSV)
- [x] Light/Dark Mode Toggle
- [x] Sidebar App Name Bug Fix
- [x] Audio Playback with Speed Controls

---

## Remaining Future Features

### Laughter Detection / Funniest Moment

**Priority:** Nice-to-have
**Status:** Not started

#### Requirements
- Audio analysis to detect laughter peaks during or after transcription
- Detect sudden high-energy bursts with multiple voices
- Mark detected moments as "funny moment" highlights with timestamp + surrounding transcript text
- Display as highlight cards on session detail page
- Clicking jumps to that point in the audio player

#### Technical Notes
- Technically challenging — may require a separate ML model or heuristic (amplitude spikes + short duration + multiple overlapping voices)
- Could use FFT-based frequency analysis to distinguish laughter from speech

#### Key Files
- New `lib/services/audio/laughter_detector.dart`
- New `lib/ui/widgets/funny_moment_card.dart`
- Integration with audio player for seek-to-timestamp

---

### Integrated Adventures

**Priority:** Long-term
**Status:** Not started

#### Requirements
- Phase 1: Curated adventure module data structure (title, description, chapters, key NPCs, locations, items, encounter notes)
- GM can reference an adventure while running a session
- Adventure entities auto-populate the world database
- Phase 2 (long-term): User marketplace for sharing/selling adventure modules

#### Key Files
- New `lib/data/models/adventure.dart`
- New `lib/data/repositories/adventure_repository.dart`
- New screens for adventure browsing/viewing

---

### User Path Tests (Integration/E2E)

**Priority:** Quality
**Status:** Not started

#### Requirements
- Write integration tests for critical user journeys:
  - Create campaign -> start session -> record -> stop -> view processed session
  - Retry failed transcription -> transcript appears
  - Edit transcript -> save -> revert to original
  - Manual session add -> appears in list
  - Navigate through all main screens without errors

#### Key Files
- `integration_test/` directory
- `test/` for widget tests of each flow

---

### TTS Audio for Podcast Scripts

**Priority:** Enhancement
**Status:** Not started

#### Requirements
- Convert generated podcast scripts to audio using TTS service (Google Cloud TTS or similar)
- Store as a separate audio file linked to the session
- Playable from session detail page via the existing audio player
- Attachable to player emails

#### Technical Notes
- Podcast scripts are already generated (v0.2.0) — this extends them with audio output
- Could use the Google Cloud TTS API or a local TTS engine

---

### Supabase Cloud Sync

**Priority:** Long-term
**Status:** Not started (infrastructure exists)

#### Requirements
- Optional cloud sync via Supabase (PostgreSQL, auth, storage)
- Sync sessions, entities, and audio between devices
- User authentication for multi-device access
- `user_id` fields already present in all models

---

### Auto-Generate Session Name from AI Summary

**Priority:** Enhancement
**Status:** Not started

#### Requirements
- After AI processing completes, auto-generate a session title from the summary
- When editing a session title, offer 5 AI-suggested title options
- Suggestions based on key events, locations, and NPCs from the session

---

### Import Characters from D&D Beyond

**Priority:** Enhancement
**Status:** Not started

#### Requirements
- Import character data from D&D Beyond into the app's character system
- Map D&D Beyond fields (name, race, class, level, backstory, etc.) to existing Character model
- Link imported characters to a player and campaign

---

### CI/CD Pipeline

**Priority:** Quality
**Status:** Not started

#### Requirements
- GitHub Actions workflow for automated checks on push/PR
- Run `flutter analyze` — fail on any lint issues
- Run `flutter test` — fail on any test failures
- Run `dart format --set-exit-if-changed .` — enforce consistent formatting
- Build verification for all three platforms (macOS, Windows, Linux)
- Optional: artifact upload for release builds

#### Technical Notes
- No CI/CD currently configured — no `.github/workflows/` directory
- Should trigger on push to `main` and on all pull requests
- Consider caching Flutter SDK and pub dependencies for faster runs
- Platform-specific builds may need separate runners (macOS for macOS builds, etc.)

#### Key Files
- New `.github/workflows/ci.yml` — main CI workflow
- Optional `.github/workflows/release.yml` — release build + artifact upload

---

### Unit & Widget Tests

**Priority:** Quality
**Status:** Not started (3 test files exist for 178 source files)

#### Requirements
- Expand test coverage across all layers:
  - **Models:** `fromMap`/`toMap` round-trip, `copyWith`, enum parsing
  - **Repositories:** CRUD operations with in-memory SQLite
  - **Services:** Transcription manager, session processor, export service, audio chunker
  - **Providers:** State transitions, error handling, reactive invalidation
  - **Widgets:** Key components (status_badge, session_header, player_card, podcast_card)
  - **Screens:** Widget tests for critical screens (home, campaign home, session detail, recording)
- Target: at minimum one test file per repository and service

#### Technical Notes
- Existing tests: `widget_test.dart`, `connectivity_service_test.dart`, `queue_manager_test.dart`
- Mock services already exist (`MockTranscriptionService`, `MockLlmService`) — reuse for testing
- Use `sqflite_common_ffi` for in-memory database tests
- Export service already separated from FileSaver for testability

#### Key Files
- `test/data/models/` — model serialization tests
- `test/data/repositories/` — repository CRUD tests
- `test/services/` — service logic tests
- `test/providers/` — provider state tests
- `test/ui/widgets/` — widget rendering tests
- `test/ui/screens/` — screen widget tests

---

### Mobile Support

**Priority:** Long-term
**Status:** Not started

#### Requirements
- Extend beyond desktop-only MVP to iOS and Android
- Responsive layout adjustments for smaller screens
- Mobile-appropriate navigation (bottom tab bar vs sidebar)
