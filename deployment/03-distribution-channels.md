# 03 — Distribution Channels

Where and how users get the app. Start with GitHub Releases, then expand as needed.

**Prerequisites:** Signed installers from [02-installers-and-packaging.md](02-installers-and-packaging.md).

---

## GitHub Releases (Recommended First)

The simplest path to distribution. Free, reliable, and integrates with CI/CD.

### 1. Define a Release Naming Convention

Use semantic versioning with a `v` prefix for tags:

```
v1.0.0, v1.0.1, v1.1.0, v2.0.0
```

### 2. Create a Release Notes Template

Use this structure for every release:

```markdown
## What's New

- Feature: description
- Fix: description

## Downloads

| Platform | File | Size |
|----------|------|------|
| macOS | ttrpg_tracker-1.0.0-macos.dmg | ~XX MB |
| Windows (installer) | ttrpg_tracker-1.0.0-windows-setup.exe | ~XX MB |
| Windows (MSIX) | ttrpg_tracker-1.0.0-windows.msix | ~XX MB |
| Linux (AppImage) | ttrpg_tracker-1.0.0-linux-x86_64.AppImage | ~XX MB |

## Installation

**macOS:** Open the DMG and drag to Applications.
**Windows:** Run the installer and follow the prompts.
**Linux:** `chmod +x ttrpg_tracker-*.AppImage && ./ttrpg_tracker-*.AppImage`

## Requirements

- A Google Gemini API key (free tier available at ai.google.dev)
- macOS 12+, Windows 10+, or Ubuntu 22.04+ / Fedora 38+
```

### 3. Create a Release Manually (First Time)

```bash
# Tag the commit
git tag -a v1.0.0 -m "v1.0.0 — Initial public release"
git push origin v1.0.0

# Create the release with installers attached
gh release create v1.0.0 \
  --title "v1.0.0 — Initial Public Release" \
  --notes-file release-notes.md \
  ttrpg_tracker-1.0.0-macos.dmg \
  ttrpg_tracker-1.0.0-windows-setup.exe \
  ttrpg_tracker-1.0.0-linux-x86_64.AppImage
```

### 4. Add Download Badges to README

```markdown
[![Download for macOS](https://img.shields.io/badge/macOS-Download-blue)](https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest)
[![Download for Windows](https://img.shields.io/badge/Windows-Download-blue)](https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest)
[![Download for Linux](https://img.shields.io/badge/Linux-Download-blue)](https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest)
```

---

## Direct Download (Website)

Pair with your landing page (see [08-landing-page.md](08-landing-page.md)).

### 1. Choose a File Hosting Strategy

**Option A: GitHub Releases as backend** (recommended)
- Download links point directly to GitHub Release assets
- No hosting cost, unlimited bandwidth
- URL pattern: `https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest/download/FILENAME`

**Option B: Cloud storage (S3, R2, etc.)**
- Upload installers to AWS S3 or Cloudflare R2
- Put a CDN (CloudFront, Cloudflare) in front for fast global downloads
- More control over analytics and download tracking

### 2. Create Platform-Detection Download Button

On your landing page, detect the user's OS and highlight the matching download:

```javascript
const platform = navigator.platform.toLowerCase();
if (platform.includes('mac')) {
  // Highlight macOS download
} else if (platform.includes('win')) {
  // Highlight Windows download
} else {
  // Highlight Linux download
}
```

Show all platform options below the primary button so users can choose manually.

---

## Mac App Store

### 1. Register the App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com/)
2. Click **My Apps → +** → **New App**
3. Platform: macOS
4. Bundle ID: `com.gatewayadventure.ttrpgTracker`
5. Fill in name, subtitle, category (Utilities or Games > Role Playing)

### 2. Configure Sandboxing

The Mac App Store requires App Sandbox. Add to entitlements:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

**Warning:** Sandboxing restricts file system access. Test that audio recording, image storage, and SQLite database paths all work within the sandbox container (`~/Library/Containers/com.gatewayadventure.ttrpgTracker/`).

### 3. Prepare for Review

- Provide a demo video or screenshots showing audio recording functionality
- Explain in the review notes why the app needs microphone access
- Ensure the app functions without a Gemini API key (graceful degradation)

### 4. Submit for Review

Build with `flutter build macos --release`, archive via Xcode, and upload through **Xcode → Product → Archive → Distribute App → App Store Connect**.

---

## Microsoft Store

### 1. Register as a Microsoft Developer

1. Go to [partner.microsoft.com](https://partner.microsoft.com/)
2. Register with a one-time fee (~$19 individual, ~$99 company)

### 2. Create the MSIX with Store Association

In `pubspec.yaml` `msix_config`, set the publisher to match your Partner Center identity. Then build:

```bash
dart run msix:create --store
```

### 3. Submit via Partner Center

1. Create a new app submission in Partner Center
2. Upload the MSIX package
3. Fill in store listing: description, screenshots, categories
4. Submit for certification

---

## Snap Store

### 1. Create a Snapcraft Account

Register at [snapcraft.io](https://snapcraft.io/).

### 2. Register the Snap Name

```bash
snapcraft register ttrpg-tracker
```

### 3. Upload and Release

```bash
snapcraft upload ttrpg-tracker_1.0.0_amd64.snap --release=stable
```

### 4. Set Up Auto-Publishing

Connect your GitHub repo to Snapcraft's build service for automatic publishing from CI. See [05-ci-cd-pipeline.md](05-ci-cd-pipeline.md).

---

## Flathub (Alternative Linux)

### 1. Create a Flathub Submission

1. Fork the [Flathub repository](https://github.com/flathub/flathub)
2. Create a manifest file: `com.gatewayadventure.ttrpgTracker.yml`
3. Submit a pull request
4. Wait for Flathub review

This is more complex than Snap and can be deferred to a later release.

---

## Recommended Rollout Order

1. **GitHub Releases** — immediate, free, developer-friendly
2. **Landing page + direct download** — for non-GitHub users
3. **Snap Store** — easiest Linux store submission
4. **Microsoft Store** — reach Windows users who prefer the store
5. **Mac App Store** — broadest macOS reach, but sandboxing may require code changes

---

## Next Steps

Once users can download the app, set up auto-updates so they stay current: [04-auto-updates.md](04-auto-updates.md).
