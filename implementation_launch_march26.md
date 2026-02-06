# Multi-Platform Future-Proofing Plan: Web + iOS + Android

## Context

History Check is a working desktop-only (macOS/Windows/Linux) Flutter app for Game Masters. It records TTRPG sessions, transcribes audio, and uses Gemini AI to generate summaries and extract entities. The goal is to expand to **web + iOS + Android** with authentication, cloud sync, and subscriptions — while preserving the existing offline-first desktop experience.

**Launch strategy:** Desktop + Web simultaneously, then iOS + Android.

**Key decisions:**
- RevenueCat for cross-platform subscriptions (Stripe on web, Apple IAP, Google Play Billing)
- Supabase Auth for authentication (email, Google, Apple sign-in)
- Supabase Storage for cloud audio files
- Gemini cloud transcription on web/mobile (keep local Whisper on macOS)
- Full Flutter web app (same codebase compiled to web)
- Offline recording on mobile, online processing
- Free tier: 3 sessions/month with basic summaries

---

## Phase 1: Platform Abstraction Layer

**Goal:** Make the codebase compile on web by removing all `dart:io` hard dependencies.

15 files currently import `dart:io`. The web compiler will refuse to build any file that touches it.

### 1A. Database — Conditional Factory

**File:** `lib/data/database/database_helper.dart` (117 lines)

Create platform-specific database factories using conditional imports:

```
lib/data/database/database_factory.dart           # Abstract factory + conditional import
lib/data/database/database_factory_native.dart    # sqflite_ffi (desktop/mobile)
lib/data/database/database_factory_web.dart       # sqflite_common_ffi_web (IndexedDB-backed)
```

- `database_helper.dart` calls `PlatformDatabaseFactory.openDatabase()` instead of `sqfliteFfiInit()` + `databaseFactoryFfi` directly
- All 10 repository files remain unchanged — they use the `Database` interface

**Add to pubspec.yaml:** `sqflite_common_ffi_web: ^0.4.0`

### 1B. File System — Platform Service

**Files affected:** `audio_recording_service.dart`, `recording_recovery_service.dart`, `file_saver.dart`, `audio_playback_service.dart`, `audio_chunker.dart`, `wav_resampler.dart`, `gemini_transcription_service.dart`, `transcription_manager.dart`, `post_session_screen.dart`, `playback_providers.dart`

Create a platform file service with conditional imports:

```
lib/services/platform/platform_file_service.dart         # Abstract interface
lib/services/platform/platform_file_service_native.dart  # dart:io File/Directory
lib/services/platform/platform_file_service_web.dart     # Blob/IndexedDB/browser downloads
```

**Interface methods:** `readFileBytes`, `writeBytes`, `fileExists`, `fileSize`, `deleteFile`, `getAppDirectory`, `getAudioDirectory`, `triggerDownload` (web-only export)

### 1C. Audio Preprocessor — Skip Chunking on Web

`audio_chunker.dart` and `wav_resampler.dart` use `RandomAccessFile` (heavy `dart:io`). On web/mobile, Gemini handles audio directly — no local chunking needed.

- Extract `AudioPreprocessor` interface
- Native implementation: existing chunker + resampler
- Web implementation: pass raw bytes directly to Gemini
- `TranscriptionManager` accepts `AudioPreprocessor` via provider

### 1D. Platform Detection

**File:** `lib/providers/transcription_providers.dart` (line 16: `Platform.isMacOS`)

Create `lib/services/platform/platform_info.dart`:
- Uses `kIsWeb` + `defaultTargetPlatform` (no `dart:io` import)
- Properties: `isWeb`, `isMacOS`, `isDesktop`, `isMobile`, `supportsLocalWhisper`

### 1E. Entry Point Guard

**File:** `lib/main.dart` — `JustAudioMediaKit.ensureInitialized()` is desktop-only.
Guard behind `PlatformInfo.isDesktop`. On web, `just_audio` works natively.

### 1F. Secure Storage Verification

`flutter_secure_storage` has web support via `useWebCrypto`. Verify it works; if not, provide `SharedPreferences` fallback on web in `env_config.dart`.

**Verification:** `flutter build web` compiles successfully. All existing desktop tests still pass.

---

## Phase 2: Authentication (Supabase Auth)

**Goal:** Add user accounts. Required for cloud sync, subscriptions, and multi-device.

### 2A. Supabase Project Setup (non-code)
- Create Supabase project
- Enable email/password + Google OAuth
- Apple OAuth deferred to Phase 7 (needs Apple Developer account)
- Add Supabase URL + anon key to `.env`

### 2B. Auth Service Layer

```
lib/services/auth/auth_service.dart            # Interface: signIn, signUp, signOut, deleteAccount
lib/services/auth/supabase_auth_service.dart   # Supabase implementation
lib/services/auth/auth_state.dart              # AuthStatus enum + user state
lib/providers/auth_providers.dart              # StreamProvider for auth state
```

### 2C. Supabase Init

**Modify:** `lib/main.dart` — add `Supabase.initialize()` before `runApp()`. Package already in pubspec.

### 2D. Auth Screens

```
lib/ui/screens/auth/sign_in_screen.dart
lib/ui/screens/auth/sign_up_screen.dart
lib/ui/screens/auth/forgot_password_screen.dart
lib/ui/screens/auth/account_screen.dart        # Profile, sign out, delete account
```

Design: Notion-style centered card. Email field, password, "Sign in with Google" button.

### 2E. Route Guard

**Modify:** `lib/config/routes.dart` — add `redirect` to GoRouter:
- Unauthenticated + not on auth routes → redirect to sign-in
- Authenticated + on auth routes → redirect to home

### 2F. User Migration

**Modify:** `lib/data/repositories/user_repository.dart` — currently hardcodes `defaultUserId = '00000000-...-000000000001'`.

On first sign-in: update all `user_id` references from default UUID to Supabase auth user ID. Flag migration complete in SharedPreferences.

**Verification:** Sign up → onboarding → home → sign out → sign in → all data present.

---

## Phase 3: Cloud Sync (Supabase DB + Storage)

**Goal:** Sync local data to cloud for multi-device access. Essential for web (no persistent filesystem).

### 3A. Supabase PostgreSQL Schema
- Mirror 23 SQLite tables in Supabase PostgreSQL
- Add Row Level Security (RLS): users can only access their own data
- RLS chain: `users` → `worlds` → `campaigns` → `sessions` → child tables

### 3B. Supabase Storage Buckets
- `session-audio` bucket — path: `{user_id}/{session_id}/{filename}`
- Storage policies: authenticated users read/write own files only

### 3C. Sync Service

```
lib/services/sync/sync_service.dart          # Orchestrator
lib/services/sync/sync_state.dart            # Status model
lib/services/sync/audio_upload_service.dart   # Background audio upload
lib/services/sync/offline_queue.dart          # Queue changes when offline
lib/providers/sync_providers.dart
```

**Strategy:** Local-first with cloud push
1. All writes go to local SQLite first
2. Queue sync operations after each write
3. Push to Supabase when online
4. Pull remote changes on app start / reconnect
5. Conflict resolution: `updated_at` timestamp wins

### 3D. DB Migration v3→v4
`ALTER TABLE ... ADD COLUMN sync_status TEXT DEFAULT 'pending'` on all synced tables.

### 3E. Web Direct-to-Cloud
On web: IndexedDB SQLite is a cache. Audio goes directly to Supabase Storage after recording (no persistent local file).

**Verification:** Record on desktop → session appears on web. Edit on web → changes sync to desktop.

---

## Phase 4: Subscription System (RevenueCat)

**Goal:** Monetize with Free / Basic / Advantage tiers.

### 4A. Tier Feature Matrix

| Feature | Free | Basic £4.99/mo | Advantage £9.99/mo |
|---------|------|----------------|---------------------|
| Sessions/month | 3 | Unlimited | Unlimited |
| Max recording | 2 hours | 6 hours | Unlimited |
| AI summary | 1 paragraph | Full | Full + enhanced |
| Entity extraction | NPCs only | Full | Full + relationships |
| Action items / Player moments | No | Yes | Yes |
| Podcast script | No | No | Yes |
| Cloud sync | No | Yes | Yes |
| Cloud audio storage | 0 GB | 10 GB | 50 GB |
| Export formats | Markdown | MD + JSON | MD + JSON + CSV |
| Email notifications | No | Yes | Yes |
| Multi-device | 1 | 2 | Unlimited |

### 4B. RevenueCat Setup (non-code)
- Create RevenueCat project
- Configure Stripe for web payments
- Apple/Google configured in Phases 7/8
- Products: `basic_monthly`, `basic_annual`, `advantage_monthly`, `advantage_annual`

**Add to pubspec.yaml:** `purchases_flutter: ^8.0.0`

### 4C. Subscription Service

```
lib/services/subscription/subscription_service.dart      # Interface
lib/services/subscription/revenuecat_subscription.dart   # RevenueCat implementation
lib/services/subscription/subscription_state.dart        # Tier, entitlements, usage
lib/services/subscription/feature_gate.dart              # Static access checks
lib/providers/subscription_providers.dart
```

### 4D. Feature Gating Integration

**Files to modify:**
- `recording_screen.dart` — check session limit + recording length
- `session_processor.dart` — limit which AI steps run per tier
- `export_service.dart` — limit export formats
- `podcast_generator.dart` — Advantage only
- `notification_service.dart` — paid only
- `sync_service.dart` — paid only

### 4E. Paywall UI

```
lib/ui/screens/subscription/paywall_screen.dart        # Tier comparison + purchase
lib/ui/screens/subscription/subscription_screen.dart   # Manage current plan
lib/ui/widgets/upgrade_prompt.dart                     # "Upgrade to unlock" inline widget
```

### 4F. Session Counter
Track sessions/month in SharedPreferences. Reset on month change. Show remaining on home screen for free users.

**Verification:** Free user hits 3-session limit → paywall → subscribe → feature unlocked → verify on second device.

---

## Phase 5: Web Launch

**Goal:** Deploy Flutter web app.

### 5A. Build Configuration
- `flutter build web --release --web-renderer canvaskit`
- PWA manifest: `web/manifest.json` with app name, icons, theme color
- Service worker for offline asset caching

### 5B. Web Audio Handling
- `record` ^6.0 supports web via MediaRecorder API (produces WebM/OGG, not WAV)
- `GeminiTranscriptionService` must accept bytes + MIME type (not just file path)
- Add "keep tab active" warning during recording

### 5C. Web Export
- No filesystem access — `FileSaver` web implementation triggers browser download via `AnchorElement`

### 5D. Deployment
- Firebase Hosting or Vercel
- Custom domain: `app.historycheck.com` or similar
- HTTPS required for microphone access

### 5E. Web Limitations (document for users)
- No background recording (tab must stay active)
- No local Whisper transcription (always Gemini cloud)
- Audio format: WebM/OGG (not WAV)

**Verification:** Full user flow in Chrome, Firefox, Safari, Edge: sign up → create campaign → record → transcribe → view summary → export.

---

## Phase 6: Mobile UI Adaptation

**Goal:** Make all 35+ screens work on phones and tablets.

### 6A. Adaptive Navigation

**Modify:** `lib/ui/widgets/app_shell.dart` (249 lines)

Currently: always `Row([Sidebar, Content])` with auto-collapse at 1024px.

Add mobile layout branch:
```dart
if (screenWidth >= Spacing.breakpointTablet) {
  // Desktop: sidebar + content (current)
} else {
  // Mobile: bottom nav + content (no sidebar)
}
```

**New file:** `lib/ui/widgets/app_bottom_nav.dart`

Bottom nav items: Home, Campaigns, Record (center), World, More

### 6B. Responsive Screen Adjustments
- Remove `maxContentWidth: 800` constraint on mobile (use full width)
- Convert `Row` layouts to `Column` on narrow screens
- `Wrap` for card grids (stats screen already does this)
- Increase touch targets where needed

### 6C. Mobile-Specific Features

**Add to pubspec.yaml:**
- `wakelock_plus: ^1.0.0` — keep screen on during recording
- `flutter_local_notifications: ^18.0.0` — notify when processing completes

**Add to recording service:**
- Background audio recording (app backgrounded)
- Screen wake lock during recording

### 6D. Permission Handling
- Runtime microphone permission request with explanation dialog
- Handle permission denied gracefully

**Verification:** Test on iPhone SE (small), iPhone 15 (medium), iPad, Android phone, Android tablet. All screens render. Recording works in background.

---

## Phase 7: iOS Launch

**Goal:** Ship on App Store.

### 7A. Apple Developer Setup (non-code)
- Enroll in Apple Developer Program ($99/year)
- Bundle ID: `com.historycheck.app`
- Enable: Push Notifications, Sign in with Apple, In-App Purchase
- Create provisioning profiles

### 7B. Sign in with Apple

**Modify:** `supabase_auth_service.dart` — enable `signInWithApple()` method.

**Add to pubspec.yaml:** `sign_in_with_apple: ^6.0.0`

**Modify:** `ios/Runner/Info.plist` — add Apple sign-in capability.

Required because the app offers Google sign-in.

### 7C. iOS In-App Purchases
- Create subscriptions in App Store Connect
- Configure RevenueCat with App Store Connect API key
- Products match web Stripe: `basic_monthly`, `basic_annual`, `advantage_monthly`, `advantage_annual`

### 7D. iOS Configuration

**Modify `ios/Runner/Info.plist`:**
- `NSMicrophoneUsageDescription`: "History Check records your tabletop RPG sessions to generate AI-powered summaries and campaign notes."
- Background audio mode for recording while backgrounded
- Minimum iOS 16.0

### 7E. App Store Compliance
- Privacy Policy URL (hosted)
- Terms of Service URL
- "Restore Purchases" button on paywall
- Account deletion in account screen
- AI disclosure: summaries generated by AI, clearly labeled
- Free trial terms displayed clearly
- Screenshots: iPhone 6.7", 6.1", iPad 12.9"

### 7F. TestFlight Beta
- Internal testing first
- External beta for 5-10 GMs

**Verification:** Full flow on physical iPhone + iPad. TestFlight submission succeeds. IAP purchase + restore works.

---

## Phase 8: Android Launch

**Goal:** Ship on Google Play Store.

### 8A. Google Play Setup (non-code)
- Google Play Developer account ($25 one-time)
- Create app listing
- Configure Google Play Billing

### 8B. Android Configuration

**Modify `android/app/src/main/AndroidManifest.xml`:**
- `RECORD_AUDIO` permission
- `INTERNET` permission
- `FOREGROUND_SERVICE` for background recording

**Modify `android/app/build.gradle`:**
- `minSdkVersion 21`, `targetSdkVersion 34`

### 8C. Google Play Billing
- Create subscription products in Play Console (match iOS/web)
- Configure RevenueCat with Google credentials

### 8D. Play Store Compliance
- Privacy Policy URL
- Data Safety section (declare all data collected)
- Content rating questionnaire

**Verification:** Full flow on physical Android device. Play Billing purchase works. Background recording works.

---

## Legal & Compliance Checklist

### Privacy Policy (required by all platforms)

Must disclose:
- **Data collected:** email, name, audio recordings, transcripts, AI-generated content
- **Third-party processors:** Google Gemini (AI), Supabase (storage/auth), Resend (email), RevenueCat (payments)
- **Audio handling:** sent to Google Gemini for transcription, not used for model training (verify Gemini API TOS)
- **Data retention:** until user deletes; account deletion removes all data
- **GDPR:** right to access, deletion, portability (export feature exists)
- **CCPA:** do not sell, right to know, right to delete
- **Children:** not intended for under-13, no data knowingly collected

**Host at:** `historycheck.app/privacy`

### Other Legal Requirements
- Terms of Service at `historycheck.app/terms`
- Cookie policy for web (GDPR)
- Subscription auto-renewal disclosure per Apple/Google requirements
- EULA for App Store
- Account deletion feature (required by Apple + GDPR)
- Unsubscribe link in all emails (CAN-SPAM)

---

## Apple App Store Specific Rules

### What Apple Requires
- **Microphone permission:** Clear description of why (recording TTRPG sessions)
- **AI disclosure:** State that content is AI-generated; no hallucinated "facts" as truth
- **Sign in with Apple:** Mandatory if any social login is offered
- **In-App Purchases ONLY:** Cannot link to external checkout, mention cheaper prices, or say "subscribe on website"
- **Restore Purchases button:** Must be visible on paywall
- **Account deletion:** Must be available inside the app
- **Privacy Policy:** Hosted URL required

### What Apple Prohibits
- Linking to Stripe checkout from iOS app
- Mentioning cheaper web pricing
- "Subscribe on our website" language
- Fake free tier (must be genuinely usable)
- Marketing/spam emails without consent

### Apple-Safe Language
- "Subscriptions are managed through your Apple ID"
- Never reference external pricing or payment methods

---

## Cross-Platform Subscription Architecture

### The Golden Rule
One backend subscription model, platform-specific purchase methods.

| Platform | Payment Method |
|----------|---------------|
| iOS | Apple In-App Purchases (via RevenueCat) |
| Android | Google Play Billing (via RevenueCat) |
| Web | Stripe (via RevenueCat) |
| Desktop | Stripe (via RevenueCat) |

### Cross-Platform Entitlement Sync
- User purchases on any platform → RevenueCat records entitlement
- On other platforms: detect active subscription via RevenueCat → unlock features silently
- Apple allows this ("reader-style entitlement sync") as long as you don't tell iOS users to subscribe elsewhere

### Pricing Strategy (Apple-safe)
- Same tier names across platforms
- Similar pricing (not necessarily identical after tax/fees)
- Never surface cross-platform price comparisons
- Web can offer annual discounts, coupons, team plans — just not visible inside iOS app

---

## Timeline

| Phase | Duration | Prerequisites |
|-------|----------|---------------|
| 1. Platform Abstraction | 3-5 days | None |
| 2. Authentication | 4-6 days | Phase 1 |
| 3. Cloud Sync | 7-10 days | Phases 1 + 2 |
| 4. Subscriptions | 5-7 days | Phase 2 |
| 5. Web Launch | 4-6 days | Phases 1-4 |
| 6. Mobile UI | 7-10 days | Phase 1 (can parallel with 2-4) |
| 7. iOS Launch | 5-7 days | Phases 4 + 6 |
| 8. Android Launch | 3-5 days | Phases 4 + 6 |

**Total: ~8-12 weeks**

**Recommended parallel tracks:**
- Weeks 1-2: Phase 1 + start Phase 6
- Weeks 3-4: Phase 2 + continue Phase 6
- Weeks 5-7: Phase 3
- Weeks 8-9: Phase 4 + Phase 5
- Weeks 10-12: Phase 7 + Phase 8

---

## Critical Files Summary

| File | Why Critical | Phase |
|------|-------------|-------|
| `lib/data/database/database_helper.dart` | Must add conditional imports for web SQLite | 1 |
| `lib/services/audio/audio_recording_service.dart` | Heaviest dart:io usage, needs platform abstraction | 1 |
| `lib/ui/widgets/app_shell.dart` | Must add bottom nav for mobile breakpoint | 6 |
| `lib/providers/transcription_providers.dart` | Platform detection must use kIsWeb not dart:io | 1 |
| `lib/data/repositories/user_repository.dart` | Hardcoded user → Supabase auth migration | 2 |
| `lib/config/routes.dart` | Auth route guard + new auth/subscription routes | 2 |
| `lib/services/export/file_saver.dart` | Web: browser download instead of filesystem write | 1 |
| `lib/main.dart` | Supabase init + platform guards for media_kit | 1+2 |

---

## Business Setup Path

### Recommended: Launch as Individual, Convert Later
1. Apple Developer Account as Individual ($99/year) — your name appears on App Store
2. Google Play Developer Account ($25 one-time)
3. Validate demand and revenue
4. When ready: form UK Ltd, get D-U-N-S number, convert to Apple Developer Organization
5. App shows company name going forward

### Why Not Company First
- More admin, slower to launch
- Apple explicitly supports individual → organization conversion
- Validate before investing in company setup
