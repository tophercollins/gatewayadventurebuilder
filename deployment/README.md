# Deployment Playbook

Step-by-step guides for taking the TTRPG Session Tracker from local development to a distributed, signed, auto-updating desktop application.

Each file is numbered in the recommended implementation order. Work through them sequentially — later files depend on concepts and artifacts created in earlier ones.

## Reading Order

| # | File | What It Covers | Estimated Effort |
|---|------|---------------|-----------------|
| 01 | [Release Builds & Signing](01-release-builds-and-signing.md) | Platform release builds, code signing, notarization | 1–2 days |
| 02 | [Installers & Packaging](02-installers-and-packaging.md) | DMG, MSIX, Inno Setup, AppImage, Snap | 1–2 days |
| 03 | [Distribution Channels](03-distribution-channels.md) | GitHub Releases, stores, direct download | 1 day |
| 04 | [Auto Updates](04-auto-updates.md) | In-app update checking and download | 1–2 days |
| 05 | [CI/CD Pipeline](05-ci-cd-pipeline.md) | GitHub Actions: CI, build, release workflows | 1–2 days |
| 06 | [Error Reporting & Analytics](06-error-reporting-and-analytics.md) | Sentry crash reporting, privacy-friendly analytics | 1 day |
| 07 | [API Key Management](07-api-key-management.md) | Production key architecture and proxy strategy | 1–3 days |
| 08 | [Landing Page](08-landing-page.md) | Marketing website with download buttons | 1–2 days |
| 09 | [Legal](09-legal.md) | Privacy policy, terms of service, GDPR | 1 day |

## Prerequisites

Before starting, you will need:

- **Apple Developer Program** membership ($99/yr) — required for macOS code signing and notarization
- **Windows code signing certificate** (OV or EV) — purchased from DigiCert, Sectigo, or GlobalSign
- **GitHub repository** — for CI/CD workflows and release hosting
- **Sentry account** (free tier available) — for crash reporting
- **Domain name** (optional) — for landing page and download links

## Project-Specific Values

These values are referenced throughout the playbook:

| Key | Value |
|-----|-------|
| App name | `ttrpg_tracker` |
| Version | `1.0.0+1` |
| macOS bundle ID | `com.gatewayadventure.ttrpgTracker` |
| Linux app ID | `com.gatewayadventure.ttrpg_tracker` |
| Windows company | `com.gatewayadventure` |
| Platforms | macOS, Windows, Linux |
| API keys in use | Gemini (LLM + transcription), Resend (email), Supabase (future) |
| Current key storage | `flutter_secure_storage` + `.env` fallback via `flutter_dotenv` |
