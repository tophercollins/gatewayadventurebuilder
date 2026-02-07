# 08 — Landing Page

A simple static website for marketing, downloads, and documentation.

---

## Hosting

### Choose a Free Host

| Host | Pros | Best For |
|------|------|----------|
| **GitHub Pages** | Free, deploys from repo | Simple HTML/CSS |
| **Vercel** | Free tier, auto-deploys, edge CDN | Next.js, Astro, any framework |
| **Netlify** | Free tier, form handling, functions | Astro, Hugo, plain HTML |

Recommendation: **Vercel** or **Netlify** for ease of deployment and custom domain support.

---

## Framework

### Option A: Plain HTML/CSS (Simplest)

A single `index.html` file with inline or linked CSS. No build step needed.

### Option B: Astro (Recommended)

Fast static site generator with zero client-side JavaScript by default:

```bash
npm create astro@latest ttrpg-tracker-site
cd ttrpg-tracker-site
```

### Option C: Next.js Static Export

If you want React components:

```bash
npx create-next-app@latest ttrpg-tracker-site --typescript
# Configure next.config.js: output: 'export'
```

---

## Page Layout

Single-page design with these sections:

### 1. Hero Section

```
[App Icon]

TTRPG Session Tracker

Record your tabletop RPG sessions, get AI-powered
transcriptions and summaries, and build a living
encyclopedia of your campaign world.

[ Download for macOS ]  [ Windows ]  [ Linux ]
```

- Auto-detect visitor's OS and highlight the matching download button
- All three buttons always visible
- Download links point to latest GitHub Release

### 2. Feature Highlights

Three or four columns showcasing key features:

```
🎙️ Record Sessions          📝 AI Transcription        🗺️ Entity Tracking
Record directly in-app.     Whisper (macOS) or         NPCs, locations, items,
Supports 10+ hour           Gemini transcription        monsters, and organisations
sessions with crash         with automatic              automatically extracted
recovery.                   speaker detection.          from every session.

📊 Campaign Dashboard       🎧 Podcast Generation      📤 Export Everything
Stats, recent sessions,     Turn your session           Markdown, JSON, and CSV
quick links to all          summaries into              export for all session
your campaign data.         entertaining recaps.        data and entities.
```

### 3. Screenshots / Demo

- 3–4 screenshots of the app in action (dark mode recommended for visual appeal)
- Optional: short GIF or video showing the record → transcribe → summary flow
- Use actual app screenshots, not mockups

### 4. How It Works

```
1. Record your session  →  2. AI transcribes audio  →  3. Review summaries & entities
   Hit record and play.       Automatic or manual.        Edit, organize, and export.
```

### 5. Requirements

```
What you need:
- macOS 12+, Windows 10+, or Ubuntu 22.04+
- A free Google Gemini API key (for AI features)
- A microphone (built-in or external)
```

### 6. FAQ Section

| Question | Answer |
|----------|--------|
| Is it free? | The app is free. AI features require a free Gemini API key. |
| Does it work offline? | Recording and local transcription (macOS) work offline. AI processing requires internet. |
| Is my data private? | All data is stored locally on your computer. Audio is sent to Google only for transcription/processing. |
| What systems does it support? | D&D 5e, Pathfinder, and any other TTRPG — the AI is system-agnostic. |

### 7. Footer

```
GitHub  ·  Privacy Policy  ·  Terms of Service  ·  Made by Gateway Adventure
```

---

## Platform-Detection Download Button

```javascript
function getOS() {
  const ua = navigator.userAgent;
  if (ua.includes('Mac')) return 'macos';
  if (ua.includes('Win')) return 'windows';
  return 'linux';
}

document.addEventListener('DOMContentLoaded', () => {
  const os = getOS();
  const primaryBtn = document.getElementById('primary-download');
  const links = {
    macos: 'https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest/download/ttrpg_tracker-macos.dmg',
    windows: 'https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest/download/ttrpg_tracker-windows-setup.exe',
    linux: 'https://github.com/YOUR_ORG/ttrpg-tracker/releases/latest/download/ttrpg_tracker-linux-x86_64.AppImage',
  };
  const labels = { macos: 'Download for macOS', windows: 'Download for Windows', linux: 'Download for Linux' };
  primaryBtn.href = links[os];
  primaryBtn.textContent = labels[os];
});
```

---

## Custom Domain (Optional)

1. Purchase a domain (e.g., `ttrpgtracker.app` or `gatewayadventure.com`)
2. In your host (Vercel/Netlify), add the custom domain
3. Update DNS: CNAME to your host's domain
4. SSL is automatic on Vercel/Netlify

---

## SEO Basics

Add to `<head>`:

```html
<title>TTRPG Session Tracker — Record, Transcribe & Manage Your Tabletop RPG Sessions</title>
<meta name="description" content="A free desktop app for Game Masters. Record sessions, get AI transcriptions, and build a living encyclopedia of your campaign world.">

<!-- Open Graph -->
<meta property="og:title" content="TTRPG Session Tracker">
<meta property="og:description" content="Record, transcribe, and manage your tabletop RPG sessions with AI.">
<meta property="og:image" content="https://yoursite.com/og-image.png">
<meta property="og:url" content="https://yoursite.com">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="TTRPG Session Tracker">
<meta name="twitter:description" content="Record, transcribe, and manage your tabletop RPG sessions with AI.">
<meta name="twitter:image" content="https://yoursite.com/og-image.png">
```

Create an `og-image.png` (1200x630px) showing the app with a brief tagline.

---

## Analytics

Add privacy-friendly analytics to track downloads without cookies:

```html
<!-- Plausible (privacy-friendly, no cookies) -->
<script defer data-domain="yoursite.com" src="https://plausible.io/js/script.js"></script>
```

Or use Aptabase's web SDK if you're already using it in the app (see [06-error-reporting-and-analytics.md](06-error-reporting-and-analytics.md)).

---

## Deployment

### With Vercel

```bash
cd ttrpg-tracker-site
vercel
```

### With Netlify

```bash
cd ttrpg-tracker-site
netlify deploy --prod
```

### With GitHub Pages

Push to a `gh-pages` branch or configure GitHub Pages to serve from `docs/` on `main`.

---

## Next Steps

Add legal documents (privacy policy, terms of service) referenced from the landing page footer: [09-legal.md](09-legal.md).
