# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TTRPG Session Tracker — a desktop-first Flutter app for Game Masters that records tabletop RPG sessions, transcribes audio locally via whisper.cpp, and uses AI (Gemini Flash) to generate summaries, extract entities (NPCs, locations, items), and track campaign details. Offline-first architecture with optional Supabase cloud sync.

**Status:** Pre-implementation (documentation phase complete, no source code yet). Implementation follows 15 phases defined in IMPLEMENTATION_PLAN.md.

## Build & Development Commands

```bash
flutter run                    # Run the app (dev mode)
flutter build windows          # Build for Windows
flutter build macos            # Build for macOS
flutter build linux            # Build for Linux
flutter test                   # Run all tests
flutter test test/path_test.dart  # Run a single test
flutter analyze                # Static analysis (lint)
dart format .                  # Format all Dart code
```

## Tech Stack

- **Framework:** Flutter 3.38.x / Dart 3.10.x
- **Local DB:** sqflite + sqflite_common_ffi (SQLite)
- **State Management:** Riverpod 2.5.x
- **Audio:** record ^5.x
- **Transcription (MVP):** Local whisper.cpp via FFI
- **LLM:** Google Gemini 1.5 Flash
- **Backend/Sync:** Supabase (PostgreSQL, auth, storage)
- **Email:** Resend
- **Secure Storage:** flutter_secure_storage ^9.0.0

## Architecture

### Data Flow
Recording → Local Whisper transcription (offline) → AI processing via Gemini (online) → Entity extraction & summary generation → SQLite storage → Optional Supabase sync

### Key Architectural Principles
- **Offline-first:** Recording and transcription work without internet. AI processing queues until online.
- **Immutable raw data:** Audio files (`session_audio`), transcripts (`session_transcripts`), and transcript segments are never modified after creation.
- **Editable outputs:** AI-generated content (summaries, scenes, entities, action items) is editable with `is_edited` flag tracking.
- **World-level entities:** NPCs, locations, and items belong to a `world`, shared across campaigns within that world.
- **Future-proofed:** `user_id` fields included for eventual multi-user support; MVP uses a hardcoded single user.

### Planned Directory Structure
```
lib/
  main.dart
  app.dart
  config/
  models/                  # Dart data classes matching DB schema
  repositories/            # SQLite CRUD operations
  services/                # Business logic (recording, transcription, LLM, sync)
  providers/               # Riverpod providers
  ui/
    screens/               # Full-page screens (home, campaign, session, recording, etc.)
    widgets/               # Reusable components (session_card, status_badge, edit_button, etc.)
    theme/                 # app_theme.dart, colors.dart, spacing.dart, typography.dart
```

### Database Schema
25 tables defined in BACKEND_STRUCTURE.md. Key relationships:
- `worlds` → `campaigns` → `sessions` (hierarchical)
- `players` ↔ `campaigns` (many-to-many via `campaign_players`)
- `players` → `characters` → sessions (via `session_attendees`)
- `sessions` → `session_audio`, `session_transcripts`, `session_summaries`, `scenes`, `action_items`, `player_moments`
- `worlds` → `npcs`, `locations`, `items` (entity database)
- `entity_appearances` links any entity type to sessions

### Processing Pipeline
Sessions flow through a `processing_queue` table with statuses: `pending` → `processing` → `completed` / `failed`. Handles offline→online transitions and retry logic.

## Design System

- Notion/Obsidian-inspired, clean and minimal — no fantasy theming
- Dark + light mode (respects system default)
- System fonts only (Roboto/SF Pro/Segoe UI)
- 4px spacing base unit; max content width 800px (centered)
- Primary color: #2563EB (light) / #3B82F6 (dark)
- Cards: 8px radius, 16px padding, 1px border, 0 elevation
- Touch targets: 44x44px minimum; text contrast ≥ 4.5:1
- Animations: 200ms page fade, no bouncing/parallax/sliding
- Full color palette and component specs in FRONTEND_GUIDELINES.md

## Key Documentation

| File | Contents |
|------|----------|
| PRD.md | Product requirements, MVP scope, success criteria, pricing |
| TECH_STACK.md | All dependencies with versions and rationale |
| BACKEND_STRUCTURE.md | Complete 25-table schema with indexes and immutability rules |
| FRONTEND_GUIDELINES.md | Design system, colors, typography, spacing, component specs |
| IMPLEMENTATION_PLAN.md | 15-phase build sequence with dependencies and MVP checklist |
| APP_FLOW.md | 28 screens, routes, and 10 user flows |

## Implementation Phases

Phases 1-3 (setup, theme, database) are sequential prerequisites. Phases 4-5 (campaign/player management) can proceed in parallel. Phases 6-8 (recording → transcription → AI) are sequential. See IMPLEMENTATION_PLAN.md for full dependency graph.

## Constraints

- Must handle 10+ hour recordings reliably
- Must support 6-7 people in room or online audio
- Raw audio and transcripts are never auto-deleted
- API keys stored via flutter_secure_storage, never committed to git
- Desktop platforms only for MVP (Windows, Mac, Linux)
