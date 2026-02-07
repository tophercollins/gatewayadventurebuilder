# 02 — Installers & Packaging

How to package signed release builds into platform-native installers that users can download and run.

**Prerequisite:** Signed release builds from [01-release-builds-and-signing.md](01-release-builds-and-signing.md).

---

## macOS — DMG Installer

### 1. Install `create-dmg`

```bash
brew install create-dmg
```

### 2. Create the DMG

```bash
create-dmg \
  --volname "TTRPG Session Tracker" \
  --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "ttrpg_tracker.app" 150 190 \
  --hide-extension "ttrpg_tracker.app" \
  --app-drop-link 450 190 \
  "ttrpg_tracker-1.0.0-macos.dmg" \
  "build/macos/Build/Products/Release/ttrpg_tracker.app"
```

### 3. Sign the DMG

```bash
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
  ttrpg_tracker-1.0.0-macos.dmg
```

### 4. Notarize the DMG

```bash
xcrun notarytool submit ttrpg_tracker-1.0.0-macos.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

xcrun stapler staple ttrpg_tracker-1.0.0-macos.dmg
```

### 5. Verify

Open the DMG on a clean Mac (or download via browser) to confirm:
- Gatekeeper doesn't block it
- Drag-to-Applications works
- App launches after installation

---

## Windows — MSIX Package

### 1. Add the `msix` Package

In `pubspec.yaml`, add to `dev_dependencies`:

```yaml
dev_dependencies:
  msix: ^3.16.0
```

### 2. Configure MSIX Settings

Add to the bottom of `pubspec.yaml`:

```yaml
msix_config:
  display_name: TTRPG Session Tracker
  publisher_display_name: Gateway Adventure
  identity_name: com.gatewayadventure.ttrpgTracker
  publisher: CN=Your Publisher ID
  msix_version: 1.0.0.0
  logo_path: windows/runner/resources/app_icon.ico
  capabilities: microphone, internetClient
```

### 3. Build the MSIX

```bash
dart run msix:create
```

Output: `build/windows/x64/runner/Release/ttrpg_tracker.msix`

### 4. Sign the MSIX

```powershell
signtool sign /f "certificate.pfx" /p "password" `
  /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
  build\windows\x64\runner\Release\ttrpg_tracker.msix
```

### 5. Test on a Clean Machine

Copy the `.msix` to a Windows machine without dev tools installed. Double-click to install and verify:
- Installation completes without errors
- App appears in Start menu
- App launches and functions correctly

---

## Windows — Inno Setup (Alternative)

Use Inno Setup if you prefer a traditional `.exe` installer over MSIX.

### 1. Install Inno Setup

Download from [jrsoftware.org/isinfo.php](https://jrsoftware.org/isinfo.php) and install.

### 2. Create the Installer Script

Create `installers/windows/setup.iss`:

```iss
[Setup]
AppName=TTRPG Session Tracker
AppVersion=1.0.0
AppPublisher=Gateway Adventure
DefaultDirName={autopf}\TTRPG Session Tracker
DefaultGroupName=TTRPG Session Tracker
OutputBaseFilename=ttrpg_tracker-1.0.0-windows-setup
Compression=lzma2
SolidCompression=yes
OutputDir=..\..\dist

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\TTRPG Session Tracker"; Filename: "{app}\ttrpg_tracker.exe"
Name: "{autodesktop}\TTRPG Session Tracker"; Filename: "{app}\ttrpg_tracker.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\ttrpg_tracker.exe"; Description: "Launch TTRPG Session Tracker"; Flags: nowait postinstall skipifsilent
```

### 3. Compile the Installer

Open the `.iss` file in Inno Setup and click **Build → Compile**, or from the command line:

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installers\windows\setup.iss
```

### 4. Sign the Installer

```powershell
signtool sign /f "certificate.pfx" /p "password" `
  /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
  dist\ttrpg_tracker-1.0.0-windows-setup.exe
```

---

## Linux — AppImage

### 1. Install `appimagetool`

```bash
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

### 2. Create AppDir Structure

```bash
mkdir -p AppDir/usr/bin AppDir/usr/lib AppDir/usr/share/icons/hicolor/256x256/apps

# Copy the Flutter bundle
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

# Copy the app icon
cp assets/icon/app_icon.png AppDir/usr/share/icons/hicolor/256x256/apps/ttrpg_tracker.png
cp assets/icon/app_icon.png AppDir/ttrpg_tracker.png
```

### 3. Create Desktop Entry

Create `AppDir/ttrpg_tracker.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=TTRPG Session Tracker
Comment=Record, transcribe, and track tabletop RPG sessions
Exec=ttrpg_tracker
Icon=ttrpg_tracker
Categories=Game;Utility;
Terminal=false
```

Also symlink it to the AppDir root:
```bash
ln -s ttrpg_tracker.desktop AppDir/ttrpg_tracker.desktop
```

### 4. Create AppRun Script

Create `AppDir/AppRun`:

```bash
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/ttrpg_tracker" "$@"
```

```bash
chmod +x AppDir/AppRun
```

### 5. Build the AppImage

```bash
appimagetool AppDir ttrpg_tracker-1.0.0-linux-x86_64.AppImage
```

### 6. Test

```bash
chmod +x ttrpg_tracker-1.0.0-linux-x86_64.AppImage
./ttrpg_tracker-1.0.0-linux-x86_64.AppImage
```

Test on a fresh Ubuntu and Fedora VM to catch missing library dependencies.

---

## Linux — Snap (Alternative)

### 1. Create Snapcraft Configuration

Create `snap/snapcraft.yaml` in the project root:

```yaml
name: ttrpg-tracker
base: core22
version: '1.0.0'
summary: Record, transcribe, and track tabletop RPG sessions
description: |
  A desktop app for Game Masters that records tabletop RPG sessions,
  transcribes audio, and uses AI to generate summaries and extract entities.

grade: stable
confinement: strict

apps:
  ttrpg-tracker:
    command: bin/ttrpg_tracker
    plugs:
      - home
      - network
      - audio-record
      - audio-playback
      - desktop
      - desktop-legacy
      - x11
      - wayland
      - opengl

parts:
  ttrpg-tracker:
    source: .
    plugin: nil
    override-build: |
      flutter build linux --release
      mkdir -p $SNAPCRAFT_PART_INSTALL/bin
      cp -r build/linux/x64/release/bundle/* $SNAPCRAFT_PART_INSTALL/bin/
    build-snaps:
      - flutter/latest/stable
```

### 2. Build the Snap

```bash
snapcraft
```

### 3. Test Locally

```bash
sudo snap install --dangerous ttrpg-tracker_1.0.0_amd64.snap
ttrpg-tracker
```

---

## Naming Convention

Use this pattern for all installer filenames:

```
ttrpg_tracker-{version}-{platform}.{ext}
```

Examples:
- `ttrpg_tracker-1.0.0-macos.dmg`
- `ttrpg_tracker-1.0.0-windows-setup.exe`
- `ttrpg_tracker-1.0.0-windows.msix`
- `ttrpg_tracker-1.0.0-linux-x86_64.AppImage`
- `ttrpg-tracker_1.0.0_amd64.snap`

---

## Next Steps

With installers built, proceed to [03-distribution-channels.md](03-distribution-channels.md) to decide where and how users will download them.
