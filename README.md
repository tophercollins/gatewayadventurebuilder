# TTRPG Session Tracker

A desktop application for Game Masters to record, transcribe, and analyze tabletop RPG sessions. Built with Flutter for Windows, macOS, and Linux.

## Features

- **Audio Recording** - Record your TTRPG sessions with one click
- **Automatic Transcription** - Converts audio to text (mock implementation for MVP)
- **AI-Powered Analysis** - Extracts NPCs, locations, items, and action items from sessions
- **Campaign Management** - Organize multiple campaigns and worlds
- **Player Tracking** - Manage players and their characters
- **World Database** - Browse all NPCs, locations, and items across your campaign
- **Offline-First** - Recording and transcription work without internet
- **Session History** - Review past sessions with summaries and scene breakdowns

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
│   └── routes.dart           # Navigation routes
├── data/
│   ├── models/               # Data classes
│   ├── repositories/         # Database operations
│   └── database/             # SQLite setup
├── services/
│   ├── audio/                # Audio recording
│   ├── transcription/        # Speech-to-text
│   ├── processing/           # AI analysis
│   ├── connectivity/         # Network monitoring
│   └── notifications/        # Email notifications
├── providers/                # Riverpod state management
└── ui/
    ├── screens/              # Full-page screens
    ├── widgets/              # Reusable components
    └── theme/                # Colors, spacing, typography
```

## Configuration

### API Keys (Optional)

For full AI processing and email notifications, you'll need:

1. **Google Gemini API Key** - For AI-powered session analysis
2. **Resend API Key** - For email notifications

Store these securely using the app's settings (they're saved in flutter_secure_storage).

## Current Limitations (MVP)

- **Transcription** - Uses mock data; real whisper.cpp integration planned
- **AI Processing** - Requires internet connection and Gemini API key
- **Desktop Only** - No mobile support in MVP
- **Single User** - Multi-user support planned for future

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
