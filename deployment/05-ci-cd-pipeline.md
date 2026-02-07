# 05 — CI/CD Pipeline

Three GitHub Actions workflows: CI (every push), Build (on tag), Release (manual trigger).

---

## Workflow 1: CI — Lint & Test on Every Push

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test
```

### Key points

- Runs on every push to `main` and every pull request
- Caches Flutter SDK and pub cache for faster runs (~30s vs ~2min)
- Fails the build if `flutter analyze` or `flutter test` reports errors

---

## Workflow 2: Build — Create Platform Artifacts on Tag

Create `.github/workflows/build.yml`:

```yaml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build macOS release
        run: flutter build macos --release

      - name: Import signing certificate
        env:
          APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
          APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
        run: |
          echo "$APPLE_CERTIFICATE" | base64 --decode > certificate.p12
          security create-keychain -p "" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

      - name: Sign the app
        run: |
          codesign --deep --force --verify --verbose \
            --sign "Developer ID Application: ${{ secrets.APPLE_SIGNING_IDENTITY }}" \
            --options runtime \
            build/macos/Build/Products/Release/ttrpg_tracker.app

      - name: Notarize the app
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
        run: |
          ditto -c -k --keepParent build/macos/Build/Products/Release/ttrpg_tracker.app ttrpg_tracker.zip
          xcrun notarytool submit ttrpg_tracker.zip \
            --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
          xcrun stapler staple build/macos/Build/Products/Release/ttrpg_tracker.app

      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "TTRPG Session Tracker" \
            --window-pos 200 120 --window-size 600 400 \
            --icon-size 100 --icon "ttrpg_tracker.app" 150 190 \
            --hide-extension "ttrpg_tracker.app" \
            --app-drop-link 450 190 \
            "ttrpg_tracker-macos.dmg" \
            "build/macos/Build/Products/Release/ttrpg_tracker.app"
          codesign --sign "Developer ID Application: ${{ secrets.APPLE_SIGNING_IDENTITY }}" ttrpg_tracker-macos.dmg
          xcrun notarytool submit ttrpg_tracker-macos.dmg \
            --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
          xcrun stapler staple ttrpg_tracker-macos.dmg

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-dmg
          path: ttrpg_tracker-macos.dmg

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build Windows release
        run: flutter build windows --release

      - name: Sign the executable
        env:
          WINDOWS_CERTIFICATE: ${{ secrets.WINDOWS_CERTIFICATE }}
          WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
        run: |
          [System.IO.File]::WriteAllBytes("certificate.pfx", [System.Convert]::FromBase64String($env:WINDOWS_CERTIFICATE))
          & "C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe" sign `
            /f certificate.pfx /p $env:WINDOWS_CERTIFICATE_PASSWORD `
            /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
            build\windows\x64\runner\Release\ttrpg_tracker.exe
          Remove-Item certificate.pfx

      - name: Create MSIX
        run: dart run msix:create

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-msix
          path: build/windows/x64/runner/Release/*.msix

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Linux dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y clang cmake ninja-build pkg-config \
            libgtk-3-dev liblzma-dev libstdc++-12-dev \
            libmpv-dev mpv

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.x'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build Linux release
        run: flutter build linux --release

      - name: Create AppImage
        run: |
          wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
          chmod +x appimagetool-x86_64.AppImage

          mkdir -p AppDir/usr/bin AppDir/usr/share/icons/hicolor/256x256/apps
          cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

          cat > AppDir/ttrpg_tracker.desktop << 'DESKTOP'
          [Desktop Entry]
          Type=Application
          Name=TTRPG Session Tracker
          Exec=ttrpg_tracker
          Icon=ttrpg_tracker
          Categories=Game;Utility;
          Terminal=false
          DESKTOP

          cat > AppDir/AppRun << 'APPRUN'
          #!/bin/bash
          SELF=$(readlink -f "$0")
          HERE=${SELF%/*}
          export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
          exec "${HERE}/usr/bin/ttrpg_tracker" "$@"
          APPRUN
          chmod +x AppDir/AppRun

          ./appimagetool-x86_64.AppImage AppDir ttrpg_tracker-linux-x86_64.AppImage

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: linux-appimage
          path: ttrpg_tracker-linux-x86_64.AppImage
```

---

## Workflow 3: Release — Publish to GitHub Releases

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Release tag (e.g., v1.0.0)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download macOS artifact
        uses: actions/download-artifact@v4
        with:
          name: macos-dmg
          run-id: ${{ github.event.inputs.build_run_id }}

      - name: Download Windows artifact
        uses: actions/download-artifact@v4
        with:
          name: windows-msix

      - name: Download Linux artifact
        uses: actions/download-artifact@v4
        with:
          name: linux-appimage

      - name: Rename artifacts with version
        run: |
          VERSION="${{ github.event.inputs.tag }}"
          VERSION="${VERSION#v}"
          mv ttrpg_tracker-macos.dmg "ttrpg_tracker-${VERSION}-macos.dmg"
          mv *.msix "ttrpg_tracker-${VERSION}-windows.msix"
          mv ttrpg_tracker-linux-x86_64.AppImage "ttrpg_tracker-${VERSION}-linux-x86_64.AppImage"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.event.inputs.tag }}
          name: ${{ github.event.inputs.tag }}
          generate_release_notes: true
          files: |
            ttrpg_tracker-*-macos.dmg
            ttrpg_tracker-*-windows.msix
            ttrpg_tracker-*-linux-x86_64.AppImage
```

---

## GitHub Secrets to Configure

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|--------|-------------|
| `APPLE_CERTIFICATE` | Base64-encoded `.p12` file: `base64 -i certificate.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the `.p12` file |
| `APPLE_SIGNING_IDENTITY` | e.g., `Your Name (TEAM_ID)` |
| `APPLE_ID` | Apple ID email for notarization |
| `APPLE_TEAM_ID` | 10-character Apple team ID |
| `APPLE_APP_PASSWORD` | App-specific password for notarization |
| `WINDOWS_CERTIFICATE` | Base64-encoded `.pfx` file |
| `WINDOWS_CERTIFICATE_PASSWORD` | Password for the `.pfx` file |

---

## Triggering a Release

1. Push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
2. The **Build** workflow runs automatically, creating artifacts for all platforms
3. Once Build completes, go to **Actions → Release → Run workflow**
4. Enter the tag name (e.g., `v1.0.0`)
5. The Release workflow downloads the artifacts and creates a GitHub Release

---

## Next Steps

With automated builds and releases in place, add crash reporting and analytics: [06-error-reporting-and-analytics.md](06-error-reporting-and-analytics.md).
