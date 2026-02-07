# 01 — Release Builds & Code Signing

How to produce signed, distributable binaries for all three desktop platforms.

---

## macOS — Code Signing & Notarization

### 1. Enroll in Apple Developer Program

1. Go to [developer.apple.com/programs](https://developer.apple.com/programs/)
2. Sign in with your Apple ID
3. Pay the $99/yr fee
4. Wait for enrollment approval (usually same day)

### 2. Create a Developer ID Application Certificate

1. Open **Xcode → Settings → Accounts**
2. Select your Apple Developer team
3. Click **Manage Certificates**
4. Click the **+** button → **Developer ID Application**
5. Xcode generates and installs the certificate in your Keychain

Alternatively, create via [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates):
1. Click **+** → **Developer ID Application**
2. Upload a Certificate Signing Request (CSR) from Keychain Access
3. Download and double-click to install

### 3. Configure Hardened Runtime Entitlements

Edit `macos/Runner/Release.entitlements` to include required permissions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

Key entitlements:
- `device.audio-input` — microphone access for session recording
- `files.user-selected.read-write` — file picker for images and audio export
- `network.client` — Gemini API, Resend API, Supabase

### 4. Configure Xcode Signing Settings

1. Open `macos/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Under **Signing & Capabilities**:
   - Team: your Apple Developer team
   - Bundle Identifier: `com.gatewayadventure.ttrpgTracker`
   - Signing Certificate: **Developer ID Application**
4. Ensure **Hardened Runtime** is enabled

### 5. Build the Release

```bash
flutter build macos --release
```

The `.app` bundle is at:
```
build/macos/Build/Products/Release/ttrpg_tracker.app
```

### 6. Code-Sign the App Bundle

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  build/macos/Build/Products/Release/ttrpg_tracker.app
```

Replace `Your Name (TEAM_ID)` with your actual certificate identity. Find it with:
```bash
security find-identity -v -p codesigning
```

### 7. Notarize the App

Create a ZIP for notarization submission:
```bash
ditto -c -k --keepParent \
  build/macos/Build/Products/Release/ttrpg_tracker.app \
  ttrpg_tracker.zip
```

Submit to Apple's notary service:
```bash
xcrun notarytool submit ttrpg_tracker.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait
```

Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com/) → Sign-In and Security → App-Specific Passwords.

### 8. Staple the Notarization Ticket

```bash
xcrun stapler staple build/macos/Build/Products/Release/ttrpg_tracker.app
```

### 9. Verify

```bash
spctl -a -vvv build/macos/Build/Products/Release/ttrpg_tracker.app
```

Expected output should include: `source=Notarized Developer ID`.

---

## Windows — Code Signing

### 1. Purchase a Code Signing Certificate

Buy an OV (Organization Validation) or EV (Extended Validation) certificate from:
- **DigiCert** — widely trusted, fast issuance
- **Sectigo** — lower cost option
- **GlobalSign** — alternative

EV certificates remove SmartScreen warnings immediately. OV certificates require building reputation over time.

### 2. Build the Release

```bash
flutter build windows --release
```

The executable is at:
```
build/windows/x64/runner/Release/ttrpg_tracker.exe
```

### 3. Sign the Executable

Using `signtool` from the Windows SDK:

```powershell
signtool sign /f "certificate.pfx" /p "password" `
  /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
  build\windows\x64\runner\Release\ttrpg_tracker.exe
```

If using an EV certificate on a hardware token (USB):
```powershell
signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
  /a build\windows\x64\runner\Release\ttrpg_tracker.exe
```

### 4. Verify the Signature

```powershell
signtool verify /pa build\windows\x64\runner\Release\ttrpg_tracker.exe
```

Or right-click the `.exe` → Properties → Digital Signatures tab.

---

## Linux — Release Build

### 1. Build the Release

```bash
flutter build linux --release
```

The binary and libraries are at:
```
build/linux/x64/release/bundle/
```

### 2. No Code Signing Required

Linux distribution formats (AppImage, Snap, Flatpak) have their own trust mechanisms. See [02-installers-and-packaging.md](02-installers-and-packaging.md) for packaging instructions.

---

## Next Steps

With signed release builds in hand, proceed to [02-installers-and-packaging.md](02-installers-and-packaging.md) to create platform-native installers.
