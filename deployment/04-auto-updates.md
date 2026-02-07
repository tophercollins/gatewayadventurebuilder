# 04 — Auto Updates

How to notify users when a new version is available and help them upgrade.

---

## Option A: GitHub Releases + Custom Checker (Recommended for v1)

The simplest approach. The app checks GitHub's API for new releases and shows a banner.

### 1. Create a Version Check Service

Add a service that calls the GitHub Releases API on app startup:

```dart
// lib/services/update/update_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const _repoOwner = 'YOUR_ORG';
  static const _repoName = 'ttrpg-tracker';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
      );
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final latestVersion = (data['tag_name'] as String).replaceFirst('v', '');
      final packageInfo = await PackageInfo.fromPlatform();

      if (_isNewerVersion(latestVersion, packageInfo.version)) {
        return UpdateInfo(
          version: latestVersion,
          downloadUrl: data['html_url'],
          releaseNotes: data['body'] ?? '',
        );
      }
      return null;
    } catch (_) {
      return null; // Fail silently — update checks are non-critical
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  const UpdateInfo({required this.version, required this.downloadUrl, required this.releaseNotes});
}
```

### 2. Add `package_info_plus` Dependency

```bash
flutter pub add package_info_plus
```

### 3. Create a Riverpod Provider

```dart
// lib/providers/update_provider.dart

final updateInfoProvider = FutureProvider.autoDispose<UpdateInfo?>((ref) async {
  final service = UpdateService();
  return service.checkForUpdate();
});
```

### 4. Show an Update Banner

Display a non-intrusive banner at the top of the main screen when an update is available:

```dart
Consumer(builder: (context, ref, _) {
  final updateAsync = ref.watch(updateInfoProvider);
  return updateAsync.when(
    data: (info) {
      if (info == null) return const SizedBox.shrink();
      return MaterialBanner(
        content: Text('Version ${info.version} is available'),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(info.downloadUrl)),
            child: const Text('Download'),
          ),
          TextButton(
            onPressed: () => ref.invalidate(updateInfoProvider),
            child: const Text('Dismiss'),
          ),
        ],
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  );
})
```

### 5. Add "Check for Updates" in Settings

Add a button on the settings screen that manually triggers the update check:

```dart
ElevatedButton(
  onPressed: () => ref.refresh(updateInfoProvider),
  child: const Text('Check for Updates'),
)
```

### 6. Add "Skip This Version" Preference

Store a skipped version in `SharedPreferences` so dismissed updates don't reappear:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('skipped_version', info.version);
```

Filter out skipped versions in the update check.

---

## Option B: Sparkle (macOS) / WinSparkle (Windows)

For true in-app auto-updates (download + install without leaving the app).

### macOS — Sparkle

1. Download the [Sparkle framework](https://sparkle-project.org/)
2. Add `Sparkle.framework` to the macOS runner's Frameworks
3. Create an `appcast.xml` file hosted alongside your releases:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>TTRPG Session Tracker Updates</title>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:version>1.0.1</sparkle:version>
      <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
      <description>Bug fixes and improvements.</description>
      <enclosure url="https://YOUR_DOMAIN/releases/ttrpg_tracker-1.0.1-macos.dmg"
                 sparkle:edSignature="SIGNATURE"
                 length="12345678"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

4. Set the `SUFeedURL` key in `Info.plist` to point to your hosted `appcast.xml`
5. Sparkle handles download, verification, and restart

### Windows — WinSparkle

1. Download [WinSparkle](https://winsparkle.org/)
2. Add the DLL to your Windows runner
3. Create a platform channel to call WinSparkle's C API from Dart
4. Point it at the same (or separate) appcast.xml
5. WinSparkle handles download and installer execution

### Considerations

- More complex to implement than Option A
- Requires signing update packages and managing an appcast feed
- Better user experience for frequent updaters
- Recommend deferring to a later version

---

## Option C: App Store / Microsoft Store Updates

If you distribute through app stores, updates are handled automatically:

- **Mac App Store:** Users get updates via the App Store app
- **Microsoft Store:** Users get updates via the Store app
- **Snap Store:** `snap refresh` handles updates automatically

No additional implementation needed for store-distributed versions.

---

## Recommended Approach

| Phase | Strategy |
|-------|----------|
| v1.0 | Option A — GitHub Releases + banner notification |
| v2.0+ | Option B — Sparkle/WinSparkle for seamless in-app updates |
| Ongoing | Option C — Store updates for store-distributed versions |

---

## Next Steps

Automate the build and release process with CI/CD: [05-ci-cd-pipeline.md](05-ci-cd-pipeline.md).
