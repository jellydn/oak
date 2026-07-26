# External Integrations

**Analysis Date:** 2026-07-26

## APIs & External Services

**Sparkle Appcast Feed:**

- Service: GitHub raw content serving `appcast.xml`
- URL: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml` (`Oak/Oak/Services/SparkleUpdater.swift:6`)
- Auth: None — public feed, EdDSA signature verification via `SUPublicEDKey`
- Purpose: Auto-update checks (daily, `SUScheduledCheckInterval: 86400`), manual "Check for Updates", version preflight comparing installed vs. feed semver
- SDK/Client: Sparkle `SPUStandardUpdaterController` / `SPUUpdaterDelegate`

**GitHub Releases (download host):**

- DMG enclosure URLs point to `https://github.com/jellydn/oak/releases/download/vX.Y.Z/Oak-X.Y.Z.dmg` (see `appcast.xml`)
- No client SDK — Sparkle handles download + verification

**Homebrew Cask:**

- `Casks/oak.rb` — Homebrew formula distribution channel (manual, updated by release tooling)

## Data Storage

**Databases:**

- None. No database layer.

**File Storage:**

- Local filesystem only
- Bundled ambient sounds: `Oak/Oak/Resources/Sounds/ambient_{rain,forest,cafe,brown_noise,lofi}.m4a` (validated by `scripts/check-ambient-sounds.sh`)
- No user file I/O except progress data export/import (JSON/CSV via `ProgressManager.exportJSON/exportCSV/importRecords`)

**Caching:**

- None

**Local Persistence (UserDefaults):**

- `ProgressManager` — `progressHistory` key, JSON-encoded `[ProgressData]`, 90-day retention, pruned on write (`Oak/Oak/Services/ProgressManager.swift:14`)
- `PresetSettingsStore` (via `SessionDurationConfig` / `DisplayConfig` / `BehaviorConfig`) — preset minutes, display target/IDs, countdown mode, always-on-top, show-below-notch, sound flags, auto-start flag
- `KeyboardShortcutService` — `keyboardShortcutConfig` key, JSON-encoded `KeyboardShortcutConfig`
- Tests isolate with unique suite names: `OakTests.<Class>.<UUID>` (`Oak/Tests/OakTests/US001Tests.swift:12`)

## Authentication & Identity

**Auth Provider:**

- None. The app has no user accounts, no login, no network auth.

## Monitoring & Observability

**Error Tracking:**

- None (no Sentry/Crashlytics/etc.)

**Logs:**

- `os.log` `Logger` with subsystem `com.productsway.oak.app`, categories: `AudioManager`, `NotificationService`, `SparkleUpdater`
- `print()` prohibited in production by SwiftLint custom rule `no_print_statements` (warning)

## CI/CD & Deployment

**Hosting:**

- GitHub-hosted Sparkle feed + GitHub Releases for binaries
- GitHub Pages for docs site (`docs/index.html`, `CNAME`, `deploy-pages.yml`)

**CI Pipeline:**

- GitHub Actions (`.github/workflows/`):
  - `ci.yml` — lint job (`swiftlint lint --strict`) + build-and-test job (macos-26, Xcode latest-stable, unsigned)
  - `release.yml` — tagged release workflow
  - `auto-release.yml` — automated release triggers
  - `update-appcast.yml` — regenerates `appcast.xml` and signs enclosures after release
  - `deploy-pages.yml` — deploys docs to GitHub Pages

## Environment Configuration

**Required env vars:**

- None for runtime. CI uses `GITHUB_RUN_NUMBER` for build number.

**Secrets location:**

- `SPARKLE_PUBLIC_ED_KEY` build setting baked into `Oak/project.yml` (public EdDSA key, not secret)
- Code signing secrets (if any) managed by release tooling, not in repo

## Webhooks & Callbacks

**Incoming:**

- None

**Outgoing:**

- Sparkle appcast fetch (GET `appcast.xml` with cache-busting `?ts=` query)
- Sparkle DMG download (handled by Sparkle framework)
- No telemetry, no analytics, no outgoing webhooks

---

_Integration audit: 2026-07-26_
