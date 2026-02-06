# TTRPG Session Tracker

A desktop application for Game Masters to record, transcribe, and analyze tabletop RPG sessions. Built with Flutter for Windows, macOS, and Linux.

## Features

- **Audio Recording** - Record sessions with crash recovery (streaming save to disk)
- **Real Transcription** - Dual-strategy: local Whisper on macOS, Gemini Flash-Lite on Windows/Linux
- **AI-Powered Analysis** - Extracts NPCs, locations, items, action items, and player moments via Gemini
- **Campaign Management** - Create, edit, and organize multiple campaigns and worlds
- **Player Tracking** - Manage players and their characters with attendance stats
- **World Database** - Browse all NPCs, locations, and items across your campaign
- **Session Review** - Summaries, scene breakdowns, entity extraction, action items, player moments
- **Audio Playback** - Play session recordings with speed controls (0.5x-2x) and seek bar
- **AI Podcast Recap** - Generate podcast-style narrative scripts from session data
- **Stats Dashboard** - Campaign, player, and global statistics across all sessions
- **Export** - Export sessions as Markdown or JSON, entities as CSV
- **Manual Session Add** - Log sessions or paste transcripts without recording
- **Email Notifications** - GM notified when processing completes, share recaps with players via Resend
- **Dark/Light Mode** - In-app theme toggle (Light / Dark / System)
- **Offline-First** - Recording and transcription work without internet
- **Onboarding** - First-time guided walkthrough

## Tech Stack

- **Framework:** Flutter 3.38.x / Dart 3.10.x
- **State Management:** Riverpod 2.5.x
- **Local Database:** SQLite (sqflite + sqflite_common_ffi)
- **Audio Recording:** record package
- **Navigation:** GoRouter
- **AI Processing:** Google Gemini 1.5 Flash (requires API key)
- **Email Notifications:** Resend (optional, requires API key)

## Getting Started

### Prerequisites

- Flutter SDK 3.38.x or later
- Xcode (for macOS builds)
- Visual Studio (for Windows builds)
- Linux development tools (for Linux builds)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd gatewayadventurebuilder
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # macOS
   flutter run -d macos

   # Windows
   flutter run -d windows

   # Linux
   flutter run -d linux

   # Web (for quick testing)
   flutter run -d chrome
   ```

## Flutter Commands

### Development

```bash
# Run the app in debug mode
flutter run -d macos

# Hot reload (while app is running)
# Press 'r' in the terminal

# Hot restart (while app is running)
# Press 'R' in the terminal

# Quit the app
# Press 'q' in the terminal
```

### Building

```bash
# Build for macOS
flutter build macos

# Build for Windows
flutter build windows

# Build for Linux
flutter build linux
```

### Testing & Analysis

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Static analysis (linting)
flutter analyze

# Format code
dart format .
```

### Dependencies

```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Clean build cache
flutter clean
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
├── config/
│   ├── routes.dart           # GoRouter navigation (30+ routes)
│   └── env_config.dart       # API key management
├── data/
│   ├── models/               # 17 Dart data classes
│   ├── repositories/         # 8 repository classes (CRUD)
│   └── database/             # SQLite setup, schema, migrations
├── services/
│   ├── audio/                # Recording + playback
│   ├── transcription/        # Whisper (macOS) + Gemini (Win/Linux)
│   ├── processing/           # AI pipeline, podcast generator
│   ├── export/               # Markdown, JSON, CSV export
│   ├── connectivity/         # Network monitoring
│   └── notifications/        # Email via Resend
├── providers/                # 19 Riverpod provider files
├── utils/                    # Formatters, helpers
└── ui/
    ├── screens/              # 60 screen files (some in subdirectories)
    ├── widgets/              # Reusable components
    └── theme/                # Colors, spacing, typography
```

## Configuration

### API Keys (Optional)

For full AI processing and email notifications, you'll need:

1. **Google Gemini API Key** - For AI-powered session analysis
2. **Resend API Key** - For email notifications

Store these securely using the app's settings (they're saved in flutter_secure_storage).

## Current Limitations

- **Desktop Only** - No mobile support (Windows, macOS, Linux only)
- **Single User** - Multi-user support planned for future (user_id fields are in place)
- **AI Processing** - Requires internet connection and Gemini API key
- **Cloud Sync** - Supabase integration scaffolded but not yet active

## App Flow

1. **Onboarding** - First-time setup walkthrough
2. **Create Campaign** - Set up a new campaign with world name
3. **Add Players** - Add players and their characters
4. **Start Session** - Begin recording a session
5. **Stop Recording** - Audio is saved and transcribed
6. **AI Processing** - Session is analyzed for entities and summaries
7. **Review** - Browse summaries, NPCs, locations, items, and action items

## Troubleshooting

### macOS: Xcode not found
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Database errors
```bash
flutter clean
flutter pub get
```

### Keyboard exceptions on macOS
This is a known Flutter bug. The app continues to work despite the console errors.

## Documentation

- `CLAUDE.md` - Project overview and architecture
- `PRD.md` - Product requirements
- `BACKEND_STRUCTURE.md` - Database schema
- `FRONTEND_GUIDELINES.md` - Design system
- `APP_FLOW.md` - Screen flows and navigation
- `IMPLEMENTATION_PLAN.md` - Development phases
- `TECH_STACK.md` - Dependencies and versions

## License

[Your License Here]
