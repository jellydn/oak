# External Integrations

**Analysis Date:** 2026-02-15

## APIs & External Services
**Auto-Updates (Sparkle):**
- GitHub Raw Content - Serves appcast XML feed for update checks
- URL: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml` (`Oak/Oak/Info.plist` line 30, `Oak/Oak/Services/SparkleUpdater.swift` line 6)
- SDK/Client: Sparkle 2.8.1 (`SPUStandardUpdaterController`)
- Auth: None (public feed), EdDSA signature verification via `SPARKLE_PUBLIC_ED_KEY`

**Legacy Update Checker (deprecated):**
- GitHub REST API - Checks latest release version (`Oak/Oak/Services/UpdateChecker.swift` lines 102-107)
- Endpoint: `https://api.github.com/repos/jellydn/oak/releases/latest`
- Auth: None (unauthenticated, subject to rate limiting)
- SDK/Client: `URLSession` with `application/vnd.github+json` accept header

**GitHub Releases:**
- DMG distribution via GitHub Releases (`release.yml`, `auto-release.yml`)
- Download URL pattern: `https://github.com/jellydn/oak/releases/download/{tag}/Oak-{version}.dmg`

## Data Storage
**Databases:**
- None (no database)
**Local Persistence:**
- `UserDefaults` (.standard) - Session presets, display preferences, progress history, update prompts (`Oak/Oak/Services/PresetSettingsStore.swift`, `Oak/Oak/Services/ProgressManager.swift`)
- JSON-encoded `[ProgressData]` stored under `progressHistory` key (`Oak/Oak/Services/ProgressManager.swift` lines 33-34)
**File Storage:**
- Local filesystem only - Bundled ambient audio files (`ambient_rain`, `ambient_forest`, `ambient_cafe`, `ambient_brown_noise`, `ambient_lofi` in m4a/wav/mp3) (`Oak/Oak/Models/AudioTrack.swift` lines 27-42)
**Caching:**
- None (Sparkle manages its own update cache internally)

## Authentication & Identity
**Auth Provider:**
- None - No user accounts, no authentication
- App runs as a local-only utility (`LSUIElement` = true, no dock icon)

## Monitoring & Observability
**Error Tracking:**
- None (no crash reporting service)
**Logs:**
- `os.log` via `Logger` - Structured logging with subsystem `com.productsway.oak.app`
- Categories: `SparkleUpdater`, `UpdateChecker`, `AudioManager`, `NotificationService` (`Oak/Oak/Services/*.swift`)
- Available via Console.app on macOS

## CI/CD & Deployment
**Hosting:**
- GitHub Pages - Project website (`docs/`, `.github/workflows/deploy-pages.yml`)
- GitHub Releases - DMG + ZIP distribution (`.github/workflows/release.yml`)
- Homebrew Cask - `Casks/oak.rb` auto-updated by CI (`.github/workflows/update-appcast.yml` lines 236-243)
**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`) - Lint + build + test on every push/PR
- Runs on `macos-15` with latest stable Xcode
- Unsigned builds for CI (`CODE_SIGNING_ALLOWED=NO`)
**Release Pipeline:**
- `.github/workflows/auto-release.yml` - Auto-tags and releases on push to `main`
- `.github/workflows/release.yml` - Manual/tag-triggered release with DMG + ZIP
- `.github/workflows/update-appcast.yml` - Updates `appcast.xml` and `Casks/oak.rb` post-release
  - Signs DMG with Sparkle EdDSA key (`SPARKLE_PRIVATE_KEY` secret)
  - Retains only 3 most recent items in appcast

## Environment Configuration
**Required env vars (CI only):**
- `SPARKLE_PRIVATE_KEY` - EdDSA private key for signing update DMGs (GitHub Actions secret)
- `GITHUB_TOKEN` - Auto-provided by GitHub Actions for release publishing
**Required env vars (runtime):**
- None - All configuration is embedded at build time or stored in UserDefaults
**Secrets location:**
- GitHub Actions repository secrets (`SPARKLE_PRIVATE_KEY`)
- Public key embedded in `Oak/project.yml` line 28 and `Oak/Oak/Info.plist` line 32

## Webhooks & Callbacks
**Incoming:**
- None
**Outgoing:**
- None (Sparkle polls the appcast feed on a 24-hour schedule, `Oak/Oak/Info.plist` line 34 `SUScheduledCheckInterval`)

---
*Integration audit: 2026-02-15*
