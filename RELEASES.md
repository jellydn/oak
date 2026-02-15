# Release Guide

This guide covers the CI/CD pipeline and release process for Oak.

## Auto-Update System

Oak uses the [Sparkle framework](https://sparkle-project.org/) to provide automatic updates. Updates are checked automatically on launch and can be configured in Settings:

- **Automatic update checks**: Enable/disable automatic update checking (enabled by default)
- **Automatic downloads**: Enable/disable automatic download of updates (disabled by default for user control)
- **Manual check**: Check for updates on demand via Settings

The appcast feed is served from `appcast.xml` in the repository root and is automatically updated when new releases are published.
Oak is configured with Sparkle EdDSA signing (`SUPublicEDKey`) and appcast entries include `sparkle:edSignature`.

## CI/CD Pipeline

- CI runs on GitHub Actions (`.github/workflows/ci.yml`) for `push` to `main` and all PRs.
- **Auto-release** (`.github/workflows/auto-release.yml`) automatically creates a new release when changes are merged to `main`:
  - Automatically increments the patch version (e.g., `v0.1.0` → `v0.1.1`)
  - Creates a Git tag
  - Builds and publishes artifacts to GitHub Releases
- Manual release workflow (`.github/workflows/release.yml`) builds and publishes unsigned artifacts on:
  - tag push: `v*` (example: `v0.1.0`)
  - manual dispatch with a `version` input (example: `v0.1.0`)

## Creating a Manual Release

If you need to create a specific version manually:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release uploads:

- `Oak-<version>.dmg`
- `Oak-<version>.zip`

## No Apple Account Notes

- Artifacts are built unsigned (`CODE_SIGNING_ALLOWED=NO`).
- The app is not notarized.
- Users will need to bypass Gatekeeper on first launch (Right-click app -> Open).

> [!IMPORTANT]
> We don't have an Apple Developer account yet. The application will show a popup on first launch that the app is from an unidentified developer.
> 1. Click **OK** to close the popup.
> 2. Open **System Settings** > **Privacy & Security**.
> 3. Scroll down and click **Open Anyway** next to the warning about the app.
> 4. Confirm your choice if prompted.
>
> You only need to do this once.
