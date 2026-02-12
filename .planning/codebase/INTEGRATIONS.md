# External Integrations

**Analysis Date:** 2026-02-13

## APIs & External Services
**Update Checking:**
- GitHub Releases API - Checks for newer app versions on launch
- SDK/Client: `URLSession` (Foundation, no third-party SDK)
- Auth: None required (public API, unauthenticated)
- Endpoint: `GET https://api.github.com/repos/jellydn/oak/releases/latest`
- Headers: `Accept: application/vnd.github+json`, `User-Agent: Oak/{version}`

## Data Storage
**Databases:**
- None (no database)
**Local Persistence:**
- `UserDefaults` — progress history (JSON-encoded `[ProgressData]` via `Codable`)
- `UserDefaults` — update checker state (`lastPromptedUpdateVersion`, `lastPromptedUpdateAt`)
- Keys: `progressHistory`, `oak.lastPromptedUpdateVersion`, `oak.lastPromptedUpdateAt`
**File Storage:**
- Local filesystem only (asset catalog for app icon)
**Caching:**
- None

## Authentication & Identity
**Auth Provider:**
- None — no user authentication or identity system
- App runs fully offline (except optional update check)

## Monitoring & Observability
**Error Tracking:**
- None (no crash reporting or APM service)
**Logs:**
- `os.Logger` (subsystem: `com.oak.app`, category: `UpdateChecker`) — production logging
- `print()` — debug-only logging in `AudioManager`

## CI/CD & Deployment
**Hosting:**
- GitHub Releases — DMG and ZIP artifacts published via `softprops/action-gh-release@v2`
**CI Pipeline:**
- GitHub Actions
  - `ci.yml` — Build + test on every push/PR to `main` (runs on `macos-15`)
  - `release.yml` — Build release assets + publish GitHub Release on `v*` tags or manual dispatch
- Runner: `macos-15` with Xcode 16 (latest-stable)
- Code signing: disabled in CI (`CODE_SIGNING_ALLOWED=NO`)
- Release assets: built via `scripts/release/build-release-assets.sh`

## Environment Configuration
**Required env vars:**
- None — app has zero required environment variables
**Secrets location:**
- No secrets needed (GitHub API is used unauthenticated)
- CI uses default `GITHUB_TOKEN` for publishing releases (via `softprops/action-gh-release`)

## Webhooks & Callbacks
**Incoming:**
- None
**Outgoing:**
- None

---
*Integration audit: 2026-02-13*
