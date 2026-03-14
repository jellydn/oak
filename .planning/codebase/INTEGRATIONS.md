# External Integrations

**Analysis Date:** 2026-03-14

## APIs & External Services

**Auto-Updates:**
- Sparkle Framework - App auto-updates
  - SDK/Client: Swift Package (https://github.com/sparkle-project/Sparkle)
  - Version: 2.6.4+
  - Config: `SPARKLE_PUBLIC_ED_KEY` in project.yml

## Data Storage

**Databases:**
- None (local-only app)

**File Storage:**
- Local filesystem only - Bundled audio assets in `Oak/Oak/Resources/Sounds/`

**Caching:**
- UserDefaults - Local preferences storage
- PresetSettingsStore - Custom settings persistence

## Authentication & Identity

**Auth Provider:**
- None required (local-only app)

## Monitoring & Observability

**Error Tracking:**
- None (local logs only)

**Logs:**
- `os.log` - Production logging
- `print()` - Debug-only (SwiftLint warning enabled)

## CI/CD & Deployment

**Hosting:**
- None (standalone macOS app)

**CI Pipeline:**
- GitHub Actions (implied by `.changeset` directory)
- Renovate bot for dependency updates (`renovate.json`)

**Distribution:**
- Homebrew Cask (Casks/ directory)
- Direct download (implied by Sparkle integration)
- GitHub Releases

## Environment Configuration

**Required env vars:**
- None (build system uses project.yml settings)

**Secrets:**
- `SPARKLE_PUBLIC_ED_KEY` - EdDSA public key for update signature verification (in project.yml, not env)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- Sparkle update check (appcast URL configured in Sparkle)

## System Integration

**macOS APIs:**
- NSScreen - Display detection and notch detection
- NSUserNotification - System notifications
- AVAudioPlayer - Audio playback
- NSPanel/NSWindow - Notch window management

---

*Integration audit: 2026-03-14*
