# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TTRPG Session Tracker — a desktop-first Flutter app for Game Masters that records tabletop RPG sessions, transcribes audio, and uses AI (Gemini Flash) to generate summaries, extract entities (NPCs, locations, items, monsters, organisations), and track campaign details. Offline-first architecture with optional Supabase cloud sync.

**Status:** v0.4.0 — Organisations entity type + monster imagePath fix. `flutter analyze` passes with 0 issues. DB version 6.

### Version History
- **v0.0** — Initial 15-phase MVP (project setup through polish)
- **v0.1** — Real transcription: Whisper on macOS (local, free), Gemini Flash-Lite on Windows/Linux (cloud)
- **v0.2** — Feature backlog: crash recovery, reactive state, stats dashboard, export, podcast generation, email integration, manual session add, light/dark toggle, audio playback
- **v0.3** — Entity image support: image upload/display for all 7 entity types (worlds, campaigns, players, characters, NPCs, locations, items)
- **v0.4** — Organisations entity type (5th world-level entity: factions, guilds, governments, etc.) + monster imagePath fix

## Build & Development Commands

```bash
flutter run -d macos           # Run on macOS
flutter run -d windows         # Run on Windows
flutter run -d linux           # Run on Linux
flutter build macos            # Build for macOS
flutter build windows          # Build for Windows
flutter build linux            # Build for Linux
flutter test                   # Run all tests
flutter test test/path_test.dart  # Run a single test
flutter analyze                # Static analysis (lint)
dart format .                  # Format all Dart code
```

## Tech Stack

- **Framework:** Flutter 3.38.x / Dart 3.10.x
- **Local DB:** sqflite ^2.3.0 + sqflite_common_ffi ^2.3.0 (SQLite)
- **State Management:** flutter_riverpod ^2.5.0
- **Audio Recording:** record ^6.0.0
- **Audio Playback:** just_audio ^0.10.5 + just_audio_media_kit ^2.1.0
- **Transcription (macOS):** whisper_flutter_new ^1.0.1 (local whisper.cpp, free, offline)
- **Transcription (Win/Linux):** google_generative_ai ^0.4.0 (Gemini Flash-Lite cloud STT)
- **LLM Processing:** Google Gemini 1.5 Flash via google_generative_ai ^0.4.0
- **Routing:** go_router ^14.0.0
- **Backend/Sync:** supabase_flutter ^2.0.0 (scaffolded, not yet active)
- **Email:** Resend via http ^1.2.0
- **Secure Storage:** flutter_secure_storage ^9.0.0
- **Image Handling:** file_picker ^8.0.0 (OS file dialogs) + image ^4.1.0 (resize/compress)

## Architecture

### Data Flow
Recording → Transcription (Whisper on macOS / Gemini on Win+Linux) → AI processing via Gemini (online) → Entity extraction & summary generation → SQLite storage → Optional Supabase sync

### Key Architectural Principles
- **Offline-first:** Recording and transcription (macOS) work without internet. AI processing queues until online.
- **Immutable raw data:** Audio files (`session_audio`), transcripts (`session_transcripts.raw_text`), and transcript segments are never modified after creation.
- **Editable outputs:** AI-generated content (summaries, scenes, entities, action items) is editable with `is_edited` flag tracking. Transcripts have a separate `edited_text` column preserving the raw original.
- **World-level entities:** NPCs, locations, items, monsters, and organisations belong to a `world`, shared across campaigns within that world.
- **Future-proofed:** `user_id` fields included for eventual multi-user support; MVP uses a hardcoded single user.
- **Dual-platform transcription:** macOS uses local Whisper (30-min chunks, free), Windows/Linux use Gemini Flash-Lite (2-min chunks, cloud). Platform-selected at runtime via `transcriptionServiceProvider`.

### Directory Structure
```
lib/
  main.dart
  app.dart
  config/                  # routes.dart, env_config.dart, constants.dart
  data/
    models/                # 24 Dart data classes matching DB schema
    repositories/          # 10 repository files (grouped by domain)
    database/              # schema.dart, database_helper.dart (migrations)
  services/
    audio/                 # recording, playback, crash recovery
    image/                 # image storage service (pick, resize, store, delete)
    transcription/         # whisper, gemini, mock, chunker, model manager
    processing/            # session processor, LLM, queue, entity matcher, podcast, prompts/
    export/                # markdown/JSON/CSV export, file saver
    notifications/         # email service, templates
    connectivity/          # network monitoring
  providers/               # 19 Riverpod provider files
  ui/
    screens/               # 30 screens (campaign_home/, npc_detail/, onboarding/, notification_settings/, player_detail/ split into subdirectories)
    widgets/               # 30 reusable components
    theme/                 # app_theme.dart, colors.dart, spacing.dart, typography.dart
  utils/                   # formatters.dart
```

### Database Schema
27 tables defined in BACKEND_STRUCTURE.md (+ `notification_settings`). DB version 6. Key relationships:
- `worlds` → `campaigns` → `sessions` (hierarchical)
- `players` ↔ `campaigns` (many-to-many via `campaign_players`)
- `players` → `characters` → sessions (via `session_attendees`)
- `sessions` → `session_audio`, `session_transcripts`, `session_summaries`, `scenes`, `action_items`, `player_moments`
- `worlds` → `npcs`, `locations`, `items`, `monsters`, `organisations` (entity database)
- `entity_appearances` links any entity type to sessions

#### Migrations
- **v1→v2:** `ALTER TABLE session_transcripts ADD COLUMN edited_text TEXT`
- **v2→v3:** `ALTER TABLE session_summaries ADD COLUMN podcast_script TEXT`
- **v3→v4:** `CREATE TABLE monsters` + `CREATE INDEX idx_monsters_world`
- **v4→v5:** `ALTER TABLE {worlds,campaigns,players,characters,npcs,locations,items} ADD COLUMN image_path TEXT`
- **v5→v6:** `ALTER TABLE monsters ADD COLUMN image_path TEXT` + `CREATE TABLE organisations` + `CREATE INDEX idx_organisations_world`

#### SessionStatus Enum
`recording`, `transcribing`, `queued`, `processing`, `complete`, `error`, `logged`, `interrupted`
- `logged` — manually added session (no recording)
- `interrupted` — recovered from crash during recording
- Keep `status_badge.dart` switch exhaustive when adding new values

### Processing Pipeline
Sessions flow through a `processing_queue` table with statuses: `pending` → `processing` → `completed` / `failed`. Handles offline→online transitions and retry logic (max 3 attempts).

### Key State Patterns
- **Revision counter** (`StateProvider<int>`) for reactive state invalidation on data mutations
- `FutureProvider.autoDispose.family` for data loading with parameters
- `StateNotifierProvider` for complex async workflows (transcription, processing, export)
- Export service returns strings; FileSaver writes to disk (separation for testability)

## Custom Claude Code Skills

7 skills at `.claude/skills/<name>/SKILL.md`:
- `/manager` — Project coordinator, reads IMPLEMENTATION_PLAN.md
- `/engineer` — Writes production Flutter/Dart code
- `/tester` — Defines test specs + writes/runs tests
- `/cleaner` — Removes dead code, enforces consistency
- `/architect` — Read-only design validation
- `/reviewer` — Pre-commit security/quality gate
- `/debugger` — Traces root causes, minimal fixes

## Design System

- Notion/Obsidian-inspired, clean and minimal — no fantasy theming
- Dark + light mode with in-app toggle (Light / Dark / System)
- System fonts only (Roboto/SF Pro/Segoe UI)
- 4px spacing base unit; max content width 800px (centered)
- Primary color: #2563EB (light) / #3B82F6 (dark)
- Cards: 8px radius, 16px padding, 1px border, 0 elevation
- Touch targets: 44x44px minimum; text contrast >= 4.5:1
- Animations: 200ms page fade, no bouncing/parallax/sliding
- Full color palette and component specs in FRONTEND_GUIDELINES.md

## Key Documentation

| File | Contents |
|------|----------|
| PRD.md | Product requirements, MVP scope, success criteria, pricing |
| TECH_STACK.md | All dependencies with versions and rationale |
| BACKEND_STRUCTURE.md | 27-table schema with indexes, immutability rules, migrations |
| FRONTEND_GUIDELINES.md | Design system, colors, typography, spacing, component specs |
| IMPLEMENTATION_PLAN.md | 15-phase build sequence (all complete) + post-MVP checklist |
| APP_FLOW.md | 30 screens, routes, and 10 user flows |
| CHANGELOG.md | Detailed version history with file-level change tracking |
| TODO.md | Remaining future features (laughter detection, TTS, Supabase sync, mobile) |

## Constraints

- 500-line maximum per file (split large screens into subdirectories)
- Must handle 10+ hour recordings reliably (streaming flush for crash recovery)
- Must support 6-7 people in room or online audio
- Raw audio and transcripts are never auto-deleted
- API keys stored via flutter_secure_storage, never committed to git
- Desktop platforms only for MVP (Windows, Mac, Linux)
- Riverpod exclusively for state management
- Theme-based colors only (no hardcoded hex values in widgets)
- No `print()` statements (use proper logging)
