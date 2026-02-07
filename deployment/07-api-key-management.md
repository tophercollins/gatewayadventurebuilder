# 07 — API Key Management

How to handle API keys when moving from development to a distributed desktop app.

**Current state:** Gemini key loaded from `.env` via `flutter_dotenv`, then stored in `flutter_secure_storage`. Users have no UI to manage keys. Direct API calls from client to Google Gemini and Resend.

---

## Step 1: Add API Key Settings UI

Give users a way to enter and manage their own API keys.

### 1. Add "API Keys" Section to Settings Screen

Create a new section on the existing settings screen with:
- Text field for Gemini API key
- Text field for Resend API key (optional, for email features)
- Each field shows masked key (last 4 characters only): `••••••••abcd`

### 2. Save Keys to Secure Storage

Use the existing `EnvConfig` / `flutter_secure_storage` integration:

```dart
Future<void> saveGeminiKey(String key) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: 'gemini_api_key', value: key);
}
```

### 3. Show Key Status

For each key, show one of:
- **Not configured** — no key entered
- **Configured** — key is saved (show last 4 chars)
- **Invalid** — test request returned an auth error

### 4. Add "Test Connection" Button

For each key, add a button that makes a minimal API call to verify the key works:

```dart
// Gemini: send a trivial prompt
Future<bool> testGeminiKey(String key) async {
  try {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
    await model.generateContent([Content.text('Say "ok"')]);
    return true;
  } catch (_) {
    return false;
  }
}
```

### 5. Mask Key Display

Never show the full key in the UI:

```dart
String maskKey(String key) {
  if (key.length <= 4) return '••••';
  return '${'•' * (key.length - 4)}${key.substring(key.length - 4)}';
}
```

---

## Step 2: Remove `.env` from Build Artifacts

Ship the app without any embedded keys. Users must enter their own.

### 1. Verify `.env` is in `.gitignore`

The `.env` file is already in `.gitignore`. Confirm it's not accidentally bundled.

### 2. Remove `.env` from `pubspec.yaml` Assets (for Release)

If `.env` is listed in the `assets:` section of `pubspec.yaml`, remove it for production builds. The app should function without it.

### 3. Handle Missing Keys Gracefully

On first launch, if no Gemini key is configured:
- Show a setup screen explaining that a Gemini API key is required
- Provide a direct link to [ai.google.dev](https://ai.google.dev/) where users can get a free key
- Allow the user to skip and use the app without AI features (manual session logging still works)

### 4. First-Launch Setup Wizard

Add a step to the existing onboarding flow:

```
Welcome → API Key Setup → World/Campaign Setup → Done
```

The API key step should include:
1. Brief explanation of why a key is needed
2. Link to get a free Gemini API key
3. Text field to paste the key
4. "Test" button to verify
5. "Skip for now" option

---

## Step 3 (Future): Backend Proxy

Move API keys server-side so users don't need their own keys.

### 1. Create an API Proxy

Use **Supabase Edge Functions** or **Cloudflare Workers** as a lightweight proxy:

```typescript
// Supabase Edge Function example
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const GEMINI_KEY = Deno.env.get('GEMINI_API_KEY')

serve(async (req) => {
  // Authenticate the request (license key, JWT, etc.)
  const authHeader = req.headers.get('Authorization')
  if (!isValidLicense(authHeader)) {
    return new Response('Unauthorized', { status: 401 })
  }

  // Forward to Gemini
  const body = await req.json()
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_KEY}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }
  )

  return new Response(await response.text(), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

### 2. Benefits of a Proxy

- Users don't need their own Gemini API key
- You control costs and can add rate limiting
- You can swap LLM providers without updating the app
- Usage tracking per user for billing

### 3. Add Rate Limiting

In the proxy, track usage per license key:

```typescript
// Simple rate limiting
const usageKey = `usage:${licenseKey}:${today()}`
const count = await kv.get(usageKey) ?? 0
if (count >= DAILY_LIMIT) {
  return new Response('Rate limit exceeded', { status: 429 })
}
await kv.set(usageKey, count + 1)
```

### 4. Update the App

Add a toggle in settings: "Use your own API key" vs "Use Gateway Adventure service". When using the proxy, the app sends requests to your endpoint instead of directly to Google.

---

## Step 4 (Future): License Key System

Gate access to the backend proxy behind a license key.

### 1. Choose a Provider

| Provider | Pricing | Best For |
|----------|---------|----------|
| [LemonSqueezy](https://lemonsqueezy.com/) | 5% + payment fees | Simple setup, handles tax/invoicing |
| [Keygen.sh](https://keygen.sh/) | Free tier available | Flexible licensing models |
| [Gumroad](https://gumroad.com/) | 10% | Large existing marketplace |

### 2. Integrate License Validation

On app startup:

```dart
Future<LicenseStatus> validateLicense(String licenseKey) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.lemonsqueezy.com/v1/licenses/validate'),
      body: {'license_key': licenseKey},
    );
    final data = json.decode(response.body);
    return data['valid'] ? LicenseStatus.valid : LicenseStatus.invalid;
  } catch (_) {
    // Offline — check cached validation
    return getCachedLicenseStatus();
  }
}
```

### 3. Cache License Locally

For offline use, cache the last successful validation:

```dart
// On successful validation:
await secureStorage.write(key: 'license_validated_at', value: DateTime.now().toIso8601String());
await secureStorage.write(key: 'license_key', value: licenseKey);

// On offline check:
final validatedAt = DateTime.parse(await secureStorage.read(key: 'license_validated_at') ?? '');
final isRecent = DateTime.now().difference(validatedAt).inDays < 30;
```

### 4. Feature Gating

| Tier | Features |
|------|----------|
| Free trial | 3 sessions, manual logging only |
| Basic | Unlimited sessions, BYO Gemini key |
| Pro | Unlimited sessions, proxy (no key needed), podcast generation, email |

---

## Recommended Rollout Order

1. **Step 1** — Ship with "bring your own key" UI (v1.0)
2. **Step 2** — Remove `.env` dependency, add onboarding key setup (v1.0)
3. **Step 3** — Add backend proxy when you have paying users (v2.0+)
4. **Step 4** — Add license system when you want to monetize (v2.0+)

---

## Next Steps

Create a landing page where users can learn about and download the app: [08-landing-page.md](08-landing-page.md).
