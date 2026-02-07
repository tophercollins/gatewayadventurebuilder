# 06 — Error Reporting & Analytics

Crash reporting with Sentry, privacy-friendly analytics with Aptabase, and structured logging.

---

## Sentry — Crash Reporting

### 1. Create a Sentry Account and Project

1. Go to [sentry.io](https://sentry.io/) and create a free account
2. Create a new project: Platform → **Flutter**, Type → **Desktop**
3. Copy the DSN (Data Source Name) — you'll need it for initialization

### 2. Add the Dependency

```bash
flutter pub add sentry_flutter
```

### 3. Initialize Sentry in `main.dart`

Wrap the app initialization with Sentry:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://YOUR_DSN@sentry.io/YOUR_PROJECT_ID';
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'production');
      options.tracesSampleRate = 0.2; // 20% of transactions for performance monitoring
      options.attachScreenshot = false; // Desktop — screenshots less useful
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### 4. Configure Environment per Build

Pass the environment at build time:

```bash
# Development
flutter run --dart-define=ENV=development

# Production release
flutter build macos --release --dart-define=ENV=production
```

### 5. Add Anonymous User Context

Set a stable anonymous ID so you can track issues per-installation without collecting personal data:

```dart
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setAnonymousUser() async {
  final prefs = await SharedPreferences.getInstance();
  var installId = prefs.getString('install_id');
  if (installId == null) {
    installId = const Uuid().v4();
    await prefs.setString('install_id', installId);
  }
  Sentry.configureScope((scope) {
    scope.setUser(SentryUser(id: installId));
  });
}
```

### 6. Test with an Intentional Crash

Add a temporary test button (remove before release):

```dart
TextButton(
  onPressed: () => throw Exception('Sentry test crash'),
  child: const Text('Test Crash'),
)
```

Verify the event appears in the Sentry dashboard within a few seconds.

### 7. Set Up Alerts

In Sentry → Alerts:
1. Create an alert rule for new issues: email notification
2. Optionally add Slack/Discord integration for real-time alerts
3. Set thresholds: alert if error count > 10 in 1 hour

---

## Aptabase — Privacy-Friendly Analytics

Aptabase is a privacy-friendly, open-source analytics tool. No personal data collected, no cookies. Alternative: PostHog (self-hosted or cloud).

### 1. Create an Aptabase Account

1. Go to [aptabase.com](https://aptabase.com/) and sign up (free tier: 20K events/month)
2. Create a new app
3. Copy the app key

### 2. Add the Dependency

```bash
flutter pub add aptabase_flutter
```

### 3. Initialize in `main.dart`

```dart
import 'package:aptabase_flutter/aptabase_flutter.dart';

// Inside main(), before runApp:
await Aptabase.init('YOUR_APP_KEY');
```

### 4. Track Key Events

Track only non-personal, aggregate-useful events:

```dart
// App opened
Aptabase.instance.trackEvent('app_opened');

// Session recorded
Aptabase.instance.trackEvent('session_recorded', {
  'duration_minutes': duration.inMinutes,
});

// Session processed
Aptabase.instance.trackEvent('session_processed', {
  'entities_extracted': entityCount,
});

// Export used
Aptabase.instance.trackEvent('export_used', {
  'format': 'markdown', // or 'json', 'csv'
});

// Podcast generated
Aptabase.instance.trackEvent('podcast_generated');
```

### 5. What NOT to Track

- Session content, transcripts, or summaries
- Entity names (NPC names, location names, etc.)
- Audio data or file paths
- API keys or any credentials
- Any personally identifiable information

### 6. Add Analytics Opt-Out Toggle

Add a toggle in the Settings screen:

```dart
SwitchListTile(
  title: const Text('Share anonymous usage data'),
  subtitle: const Text('Help improve the app by sharing anonymous usage statistics'),
  value: analyticsEnabled,
  onChanged: (value) {
    // Save preference and enable/disable Aptabase
  },
)
```

Respect the preference by skipping `trackEvent` calls when disabled.

---

## Structured Logging

Replace any remaining `print()` / `debugPrint()` with structured logging.

### 1. Add the `logging` Package

```bash
flutter pub add logging
```

### 2. Configure Logging

```dart
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = Level.INFO; // or Level.ALL for development
  Logger.root.onRecord.listen((record) {
    // In development: print to console
    debugPrint('${record.level.name}: ${record.loggerName}: ${record.message}');

    // In production: add as Sentry breadcrumb
    Sentry.addBreadcrumb(Breadcrumb(
      message: record.message,
      level: _toSentryLevel(record.level),
      category: record.loggerName,
    ));
  });
}

SentryLevel _toSentryLevel(Level level) {
  if (level >= Level.SEVERE) return SentryLevel.error;
  if (level >= Level.WARNING) return SentryLevel.warning;
  if (level >= Level.INFO) return SentryLevel.info;
  return SentryLevel.debug;
}
```

### 3. Usage in Services

```dart
class SessionProcessor {
  static final _log = Logger('SessionProcessor');

  Future<void> process(Session session) async {
    _log.info('Processing session ${session.id}');
    // ...
    _log.warning('Gemini rate limit hit, retrying in 5s');
    // ...
    _log.severe('Processing failed', error, stackTrace);
  }
}
```

---

## Summary

| Tool | Purpose | Privacy | Cost |
|------|---------|---------|------|
| Sentry | Crash reporting + error tracking | Anonymous user IDs only | Free tier: 5K errors/month |
| Aptabase | Usage analytics | No PII, no cookies | Free tier: 20K events/month |
| logging | Structured app logs | Local + Sentry breadcrumbs | Free |

---

## Next Steps

Secure your API keys for production distribution: [07-api-key-management.md](07-api-key-management.md).
