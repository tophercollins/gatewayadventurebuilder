# Changelog

All notable changes to this project will be documented in this file.

---

## [0.5.0] — 2026-02-07 — Characters as Global Entities

Restructures characters from campaign-scoped to player-owned global entities. Characters now survive campaign deletion, can belong to multiple campaigns via a join table (`campaign_characters`), and are accessible from a new global route. Also adds full cascade delete for worlds.

### Changed

#### Database (v6→v7)
- **`lib/data/database/schema.dart`** — Removed `campaign_id` from `characters` table; added `campaign_characters` join table with unique constraint and indexes
- **`lib/data/database/database_helper.dart`** — v6→v7 migration: creates `campaign_characters`, populates from existing data, recreates `characters` table without `campaign_id`

#### Model
- **`lib/data/models/character.dart`** — Removed `campaignId` field from constructor, `fromMap`, `toMap`, and `copyWith`
- **`lib/data/models/player.dart`** — Added `CampaignCharacter` class (mirrors `CampaignPlayer` pattern)

#### Repository
- **`lib/data/repositories/player_repository.dart`** — `createCharacter()` no longer takes `campaignId`; `getCharactersByCampaign()` and `getActiveCharacterForPlayerInCampaign()` rewritten to JOIN via `campaign_characters`; `getCharactersByUser()` simplified to JOIN via players; `deleteCharacter()` removes campaign links first; added `addCharacterToCampaign()`, `removeCharacterFromCampaign()`, `isCharacterInCampaign()`, `getCampaignsByCharacter()`
- **`lib/data/repositories/campaign_repository.dart`** — `deleteCampaign()` no longer deletes characters (only removes `campaign_characters` links); `deleteWorld()` now performs full cascade delete (campaigns, sessions, world entities, NPC children)

#### Providers
- **`lib/providers/player_providers.dart`** — `createCharacter()` takes optional `campaignId`; `updateCharacter()` and `deleteCharacter()` take optional campaign context; added `linkCharacterToCampaign()`, `unlinkCharacterFromCampaign()`, `characterCampaignsProvider`
- **`lib/providers/global_providers.dart`** — `CharacterSummary.campaignName` → `campaignNames` (List) + `campaignDisplay` getter
- **`lib/providers/stats_providers.dart`** — `CharacterStats.campaignName` → `campaignNames` (List) + `campaignDisplay` getter

#### Routes
- **`lib/config/routes.dart`** — Added `/characters/:characterId` global route with `globalCharacterDetailPath()` helper

#### UI
- **`lib/ui/screens/character_detail/character_detail_screen.dart`** — `campaignId` now nullable; delete navigates to global list when no campaign context
- **`lib/ui/screens/character_detail/character_sessions_section.dart`** — `campaignId` now nullable; falls back to session's own campaignId for routing
- **`lib/ui/screens/all_characters_screen.dart`** — Uses global character routing and `campaignDisplay`
- **`lib/ui/screens/player_detail/player_detail_screen.dart`** — Uses global character routing
- **`lib/ui/screens/add_character_screen.dart`** — Passes `campaignId` as optional named param
- **`lib/ui/screens/stats/character_stats_tab.dart`** — Uses `campaignDisplay`

---

## [0.4.0] — 2026-02-07 — Organisations Entity Type + Monster imagePath Fix

Adds **organisations** as the 5th world-level entity type (factions, guilds, governments, cults, military orders, etc.) across all layers of the app. Also fixes the missing `imagePath` field on the Monster model that was missed in the v4→v5 migration, and updates the monster detail screen to display images.

### Added

#### New Model
- **New: `lib/data/models/organisation.dart`** — Organisation data class with fields: `id`, `worldId`, `copiedFromId`, `name`, `description`, `organisationType`, `notes`, `isEdited`, `imagePath`, `createdAt`, `updatedAt`. Includes `fromMap`, `toMap`, `copyWith`.

#### New LLM Prompt
- **New: `lib/services/processing/prompts/organisation_prompt.dart`** — Extraction prompt for organisations
  - 10 types: `guild`, `faction`, `government`, `cult`, `military`, `mercenary`, `religious`, `criminal`, `noble_house`, `trade_company`
  - Output format: JSON array of `{name, description, organisation_type, context, timestamp_ms}`

#### New Screen
- **New: `lib/ui/screens/organisation_detail_screen.dart`** — Full detail screen following existing entity pattern
  - Header with `EntityImage.avatar` (icon: `Icons.groups_outlined`)
  - Info section (description, notes)
  - Appearances section (sessions where organisation was mentioned)
  - Edit form with name, type, description, notes fields
  - Uses `organisationByIdProvider` and `entitySessionsProvider`

### Changed

#### Database Migration v5→v6
- `ALTER TABLE monsters ADD COLUMN image_path TEXT` — fixes missing column from v4→v5 migration
- `CREATE TABLE organisations` — full schema with `id`, `world_id`, `copied_from_id`, `name`, `description`, `organisation_type`, `notes`, `is_edited`, `image_path`, `created_at`, `updated_at`
- `CREATE INDEX idx_organisations_world ON organisations(world_id)`
- Modified: `lib/data/database/database_helper.dart` — version bump from 5 to 6
- Modified: `lib/data/database/schema.dart` — added `_createOrganisations` table + index; added `image_path TEXT` to `_createMonsters`

#### Entity Appearance Enum
- `lib/data/models/entity_appearance.dart` — Added `organisation('organisation')` to `EntityType` enum

#### Monster Model Fix
- `lib/data/models/monster.dart` — Added `imagePath` field to constructor, class fields, `fromMap`, `toMap`, `copyWith`

#### Repository
- `lib/data/repositories/entity_repository.dart` — Added full CRUD: `createOrganisation`, `getOrganisationById`, `getOrganisationsByWorld`, `updateOrganisation`, `deleteOrganisation`

#### Processing Pipeline (7 files)
- `lib/services/processing/llm_response_models.dart` — Added `OrganisationData` class (name, description, organisationType, context, timestampMs)
- `lib/services/processing/entity_response_models.dart` — Added `OrganisationsResponse` class with `tryParse` static method
- `lib/services/processing/prompts/prompts.dart` — Added `export 'organisation_prompt.dart'` to barrel file
- `lib/services/processing/llm_service.dart` — Added `extractOrganisations()` abstract method + Gemini implementation
- `lib/services/processing/session_context.dart` — Added `existingOrganisations` field + `existingOrganisationNames` getter; updated `SessionContextLoader.load()`
- `lib/services/processing/entity_matcher.dart` — Added `matchOrganisations()`, `_findOrganisationMatch()`, `_mergeOrganisationData()`; extended `createAppearances()` with organisation loop
- `lib/services/processing/entity_extractor.dart` — Added organisation extraction step (step 5) with `OrganisationPrompt`

#### Processing Stats (2 files)
- `lib/services/processing/processing_types.dart` — Added `organisationCount` to `ProcessingResult`, `ProcessingStats`, and `EntityCounts`
- `lib/services/processing/session_processor.dart` — Accumulate `totalOrganisations` in processing loop

#### Mock LLM Service
- `lib/services/processing/mock_llm_service.dart` — Added `extractOrganisations()` override returning mock data (The Goblin Warband, Shadowfen Temple Keepers)

#### Providers (3 files)
- `lib/providers/world_providers.dart` — Added `OrganisationWithCount` data class, `worldOrganisationsProvider`, `organisationByIdProvider`; updated `WorldDatabaseData` with `organisations` field + `totalEntities` getter; added `updateOrganisation()` and `deleteOrganisation()` to `EntityEditor`
- `lib/providers/session_detail_providers.dart` — Added `organisations` field to `SessionDetailData` + updated `entityCount` getter; updated `sessionEntitiesProvider` to fetch organisation appearances
- `lib/providers/editing_providers.dart` — Added `updateOrganisation()` method to `EntityEditingNotifier`

#### UI — World Database Screen
- `lib/ui/screens/world_database_screen.dart` — Changed `DefaultTabController` length from 4 to 5; added "Orgs" tab with count; added `_OrganisationsList` widget with search filtering

#### UI — Session Entities Screen
- `lib/ui/screens/session_entities_screen.dart` — Changed `DefaultTabController` length from 4 to 5; added "Orgs" tab with count; added `_OrganisationsList` widget with inline editing

#### UI — Monster Detail Screen
- `lib/ui/screens/monster_detail_screen.dart` — Replaced hardcoded 56x56 Container+Icon with `EntityImage.avatar(imagePath: monster.imagePath, fallbackIcon: Icons.pest_control_outlined)`; added `entity_image.dart` import

#### Routes
- `lib/config/routes.dart` — Added `organisationDetail` route constant, `organisationDetailPath()` helper, and `GoRoute` for `organisations/:organisationId` under world routes

#### Export Service
- `lib/services/export/export_service.dart` — Added organisations to session Markdown, session JSON, campaign JSON, and CSV exports; added `_organisationToJson()` helper, `_exportOrganisationsCsv()` method; updated `_SessionEntities` and `_resolveSessionEntities` with organisations

### Database Changes

| Version | Migration |
|---------|-----------|
| v5→v6 | `ALTER TABLE monsters ADD COLUMN image_path TEXT` |
| v5→v6 | `CREATE TABLE organisations (...)` |
| v5→v6 | `CREATE INDEX idx_organisations_world ON organisations(world_id)` |

### Verification

- `flutter analyze` — 0 issues
- DB migration v5→v6 applies cleanly
- 3 new files, 23 modified files, 1464 insertions

---

## [0.3.0] — 2026-02-07 — Entity Image Support

Adds image upload and display for all 7 entity types. Wide 16:9 banners for campaigns, square avatars for all others. Images are picked from OS file dialogs, auto-resized on import, and stored locally as JPEG.

### Added

#### New Packages
- **`file_picker: ^8.0.0`** — Native OS file dialogs for image selection
- **`image: ^4.1.0`** — Pure Dart image resize/compress (no platform channels)

#### Image Storage Service
- **New: `lib/services/image/image_storage_service.dart`** — Core image service
  - `pickImageFile()` — Opens OS file picker filtered to png/jpg/jpeg/webp
  - `storeImage()` — Reads, resizes (banners max 1200px wide, avatars cropped to square max 512px), encodes as JPEG quality 85, stores locally
  - `deleteImage()` — Removes stored image file
  - `getImagePath()` — Returns expected storage path for an entity
  - Storage path: `{app_docs}/ttrpg_tracker/images/{entityType}/{entityId}.jpg`

#### Image Provider
- **New: `lib/providers/image_providers.dart`** — `imageStorageProvider` for DI access to `ImageStorageService`

#### Reusable UI Widgets
- **New: `lib/ui/widgets/entity_image.dart`** — Display widget with two constructors:
  - `EntityImage.avatar(imagePath, fallbackIcon, {size, borderRadius, fallbackChild})` — Square with rounded corners
  - `EntityImage.banner(imagePath, fallbackIcon)` — 16:9 aspect ratio
  - Uses `Image.file()` with `errorBuilder` for graceful fallback
- **New: `lib/ui/widgets/image_picker_field.dart`** — Form picker widget
  - Shows current/pending image with pick and remove overlay buttons
  - Callbacks: `onImageSelected(sourcePath)`, `onImageRemoved()`
  - Supports both banner and avatar modes

#### macOS Entitlements
- Added `com.apple.security.files.user-selected.read-write` to both `DebugProfile.entitlements` and `Release.entitlements`

### Changed

#### Database Migration v4→v5
- Added `image_path TEXT` column to 7 tables: `worlds`, `campaigns`, `players`, `characters`, `npcs`, `locations`, `items`
- Modified: `lib/data/database/database_helper.dart` — version bump from 4 to 5
- Modified: `lib/data/database/schema.dart` — added column to all 7 CREATE TABLE statements

#### Model Updates (7 files)
- `lib/data/models/world.dart` — added `String? imagePath` field, `fromMap`, `toMap`, `copyWith`
- `lib/data/models/campaign.dart` — same pattern
- `lib/data/models/player.dart` — same pattern
- `lib/data/models/character.dart` — same pattern
- `lib/data/models/npc.dart` — same pattern
- `lib/data/models/location.dart` — same pattern
- `lib/data/models/item.dart` — same pattern

#### Display Integration
- `lib/ui/screens/npc_detail/npc_detail_widgets.dart` — 56x56 icon → `EntityImage.avatar`
- `lib/ui/screens/location_detail_screen.dart` — header icon → `EntityImage.avatar`
- `lib/ui/screens/item_detail_screen.dart` — header icon → `EntityImage.avatar`
- `lib/ui/screens/worlds_screen.dart` — world card icon → `EntityImage.avatar(size: 40)`
- `lib/ui/widgets/player_card.dart` — `CircleAvatar` → `EntityImage.avatar` with initial-letter `fallbackChild`
- `lib/ui/widgets/entity_card.dart` — added `imagePath` param, icon → `EntityImage.avatar(size: 40)`
- `lib/ui/screens/campaign_home_screen.dart` — added `EntityImage.banner` above header when image exists

#### Form Integration (image picker added to all entity forms)
- `lib/ui/screens/npc_detail/npc_edit_form.dart` — converted to `ConsumerStatefulWidget`, added `ImagePickerField`
- `lib/ui/screens/location_detail_screen.dart` — edit form converted, added image picker
- `lib/ui/screens/item_detail_screen.dart` — edit form converted, added image picker
- `lib/ui/screens/worlds_screen.dart` — form dialog updated with image picker
- `lib/ui/screens/new_campaign_screen.dart` — added banner image picker
- `lib/ui/screens/add_player_screen.dart` — added avatar image picker
- `lib/ui/widgets/player_edit_form.dart` — converted to `ConsumerStatefulWidget`, added image picker
- `lib/ui/screens/add_character_screen.dart` — added avatar image picker
- `lib/ui/widgets/character_edit_form.dart` — converted to `ConsumerStatefulWidget`, added image picker

#### Image Cleanup on Delete
- `lib/providers/campaign_providers.dart` — `CampaignEditor.deleteCampaign()` and `WorldEditor.deleteWorld()` now delete associated images
- `lib/providers/player_providers.dart` — `PlayerEditor.deletePlayer()` and `deleteCharacter()` now delete images; `createPlayer()` and `createCharacter()` return `Future<String>` (entity ID) instead of `Future<void>`
- `lib/providers/world_providers.dart` — `EntityEditor` gained `deleteNpc()`, `deleteLocation()`, `deleteItem()` methods with image cleanup

### Database Changes

| Version | Migration |
|---------|-----------|
| v4→v5 | `ALTER TABLE {worlds,campaigns,players,characters,npcs,locations,items} ADD COLUMN image_path TEXT` |

### Verification

- `flutter analyze` — 0 issues
- DB migration v4→v5 applies cleanly
- All 7 entity types support image pick, display, and cleanup on delete

---

## [0.2.0] — 2026-02-06 — Feature Backlog (Post-MVP Enhancements)

Major feature expansion across 10 backlog items: crash recovery, reactive state, new screens, export, podcast generation, stats, email integration, and UI polish.

### Added

#### Audio Crash Recovery (P1)
- **Streaming audio save** — audio is flushed to disk periodically during recording, not just on Stop
- **Crash detection** — if the app is force-quit mid-recording, reopening recovers all audio up to the last flush point
- **`SessionStatus.interrupted`** — new session status for recovered recordings with resume/finalize options
- Modified: `lib/services/audio/audio_recording_service.dart` — periodic flush logic
- Modified: `lib/ui/screens/recording_screen.dart` — crash recovery UX

#### Reactive State (P1)
- **Revision counter pattern** — `StateProvider<int>` revision providers that increment on data mutations
- All list/detail providers now properly invalidate when underlying data changes
- Session list refreshes immediately after recording completes
- Campaign list refreshes after create/edit/delete
- Entity lists (NPCs, locations, items) refresh on creation/edit
- Modified: all providers in `lib/providers/`, all list screens in `lib/ui/screens/`

#### Manual Session Add (P2)
- **New screen: `lib/ui/screens/add_session_screen.dart`** — add sessions without recording
- **Two modes:**
  - "Log session" — minimal form (title, date, session number, attendees, notes) for stat-tracking only
  - "Add from transcript" — paste pre-existing transcript text that can trigger AI processing
- **`SessionStatus.logged`** — new session status for log-only sessions
- **New route:** `/campaigns/:id/sessions/add` with helper `Routes.addSessionPath()`
- Modified: `lib/ui/screens/campaign_home_screen.dart` — added `_AddSessionButton` widget
- Modified: `lib/config/routes.dart` — new `addSession` route
- Modified: `lib/ui/screens/screens.dart` — added export

#### Home Page Redesign (P2)
- **Two clear primary actions:** "Continue Campaign" (smart — goes to last-used campaign) and "New Campaign"
- Removed redundant "Review Sessions" card
- Smart campaign navigation via campaigns list provider
- Modified: `lib/ui/screens/home_screen.dart`

#### Stats Dashboard (P2)
- **New screen: `lib/ui/screens/stats_screen.dart`** — three-tab stats page
- **Three tabs:**
  - Overview — total campaigns, sessions, hours recorded, entities count
  - Campaigns — per-campaign stats (sessions, hours, entity counts, frequency)
  - Players — attendance rates, characters played, moments count
- **New providers: `lib/providers/stats_providers.dart`** — `GlobalStats`, `CampaignStats`, `PlayerStats` data classes with `FutureProvider.autoDispose` providers
- **New route:** `/stats` accessible from sidebar
- Modified: `lib/ui/widgets/app_sidebar.dart` — added Stats nav item
- Modified: `lib/config/routes.dart` — new `stats` route

#### Email API — Resend Integration (P3)
- **GM notification (automatic):** email sent when transcript/AI processing completes
- **Player sharing modes:** `PlayerSharingMode.reviewFirst` (default) and `autoSend`
- **Email trigger in processing pipeline:** `SessionProcessor._sendNotificationEmail()` fires after successful processing
- Modified: `lib/data/models/notification_settings.dart` — added `PlayerSharingMode` enum
- Modified: `lib/services/processing/session_processor.dart` — email trigger integration
- Modified: `lib/providers/processing_providers.dart` — wired email service

#### AI Podcast Summary (P3)
- **New service: `lib/services/processing/podcast_generator.dart`** — generates 2-3 minute podcast-style recap scripts via LLM
- **New widget: `lib/ui/widgets/podcast_card.dart`** — generate, view, regenerate, and copy podcast scripts on session detail
- **New providers: `lib/providers/podcast_providers.dart`** — `podcastGeneratorProvider`, `podcastScriptProvider`, `PodcastGenerationNotifier`
- **DB migration v2→v3:** added `podcast_script TEXT` column to `session_summaries` table
- Modified: `lib/data/models/session_summary.dart` — added `podcastScript` field
- Modified: `lib/data/database/schema.dart` — added column
- Modified: `lib/data/database/database_helper.dart` — version bump to 3, migration
- Modified: `lib/data/repositories/summary_repository.dart` — added `updatePodcastScript()`
- Modified: `lib/ui/screens/session_detail_screen.dart` — integrated PodcastCard

#### Export — Markdown, JSON, CSV (P4)
- **New service: `lib/services/export/export_service.dart`** — session Markdown, session JSON, campaign JSON, entity CSV exports
- **New utility: `lib/services/export/file_saver.dart`** — saves to `Documents/TTRPGTracker/exports/` with timestamped filenames
- **New providers: `lib/providers/export_providers.dart`** — `exportServiceProvider`, `fileSaverProvider`, `ExportStateNotifier`
- **Export UI on session detail:** Markdown and JSON export buttons with progress indicator and file path display
- Modified: `lib/ui/screens/session_detail_screen.dart` — added `_ExportSection` widget

#### Light/Dark Mode Toggle (P5)
- **In-app theme toggle** in sidebar: Light / Dark / System (default)
- Preference persisted via SharedPreferences
- New: `lib/providers/theme_provider.dart`
- Modified: `lib/ui/widgets/app_sidebar.dart` — toggle button

#### Sidebar App Name Bug Fix (P5)
- Fixed text clipping/truncation of "TTRPG Tracker" in sidebar header
- Fixed RenderFlex overflow in `_SidebarNavItem` (Row overflowed by 17px)
- Modified: `lib/ui/widgets/app_sidebar.dart`

### Changed

#### Status Badge — Exhaustive Switch
- Added `SessionStatus.logged` and `SessionStatus.interrupted` to the switch expression in `status_badge.dart`
- `logged` displays as grey "Logged" pill badge
- `interrupted` displays as amber "Interrupted" pill badge (same color as recording)

#### Providers Barrel File
- `lib/providers/providers.dart` — added exports for `export_providers.dart`, `podcast_providers.dart`, sorted alphabetically

#### Home Screen Lint Fix
- Fixed `unnecessary_underscores` warning in `home_screen.dart` error callback

### Database Changes

| Version | Migration |
|---------|-----------|
| v2→v3 | `ALTER TABLE session_summaries ADD COLUMN podcast_script TEXT` |

### Verification

- `flutter analyze` — 0 issues
- All 19 provider files compile cleanly
- All 60 screen files compile cleanly
- All 40 service files compile cleanly

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
