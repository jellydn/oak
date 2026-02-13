# Release Process with Auto-Update

This document explains how Oak's release process works with the Sparkle auto-update system.

## Overview

Oak uses [Sparkle](https://sparkle-project.org/) for automatic updates. When a new release is published, GitHub Actions automatically:

1. Builds and publishes release artifacts (DMG, ZIP)
2. Updates the Homebrew cask formula
3. Updates the Sparkle appcast feed

## Automated Workflows

### 1. Auto Release (`auto-release.yml`)

**Trigger**: Push to `main` branch

**What it does**:
- Determines the next version by incrementing the patch number
- Creates and pushes a new Git tag (e.g., `v0.3.5`)
- Builds release artifacts (DMG and ZIP)
- Publishes a GitHub release with auto-generated release notes

### 2. Update Homebrew Cask (`update-homebrew.yml`)

**Trigger**: New release published

**What it does**:
- Downloads the DMG from the release
- Calculates the SHA256 checksum
- Updates `Casks/oak.rb` with the new version and checksum
- Commits and pushes changes to `main`

### 3. Update Sparkle Appcast (`update-appcast.yml`)

**Trigger**: New release published

**What it does**:
- Downloads the DMG from the release
- Gets file size and SHA256 checksum
- Updates `appcast.xml` with a new release entry
- Commits and pushes changes to `main`

## Appcast Feed

The appcast feed (`appcast.xml`) is an RSS feed that Sparkle uses to check for updates. It contains:

- Release version and tag
- Download URL for the DMG
- File size and checksum for verification
- Release notes
- Publication date

The feed is served from the `main` branch at:
`https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml`

## How Updates Work for Users

1. **Launch Check**: Oak automatically checks for updates on launch (if enabled)
2. **Periodic Checks**: Sparkle checks for updates every 24 hours by default
3. **Update Notification**: If a newer version is found, the user is notified
4. **Download**: User can choose to download the update immediately or later
5. **Installation**: Sparkle handles the update installation automatically

## User Settings

Users can configure auto-update behavior in Oak's Settings:

- **Automatically check for updates**: Enable/disable automatic update checks (default: ON)
- **Automatically download updates**: Enable/disable automatic downloads (default: OFF)
- **Check for Updates Now**: Manually trigger an update check

## Manual Release Process

If you need to create a release manually:

```bash
# Create and push a tag
git tag v0.3.5
git push origin v0.3.5
```

This will trigger the `release.yml` workflow, which builds and publishes the artifacts. The other workflows will then update the cask and appcast automatically.

## Testing Updates

To test the update mechanism in development:

1. Build a release version with a higher version number than the current one
2. Create a local appcast feed pointing to your test build
3. Set `INFOPLIST_KEY_SUFeedURL` to your test feed URL in `project.yml`
4. Regenerate the Xcode project and build
5. Launch the app and trigger an update check

## Troubleshooting

### Updates not appearing

- Check that the appcast feed is accessible and valid XML
- Verify the version number in the appcast is higher than the current version
- Check the app's console logs for Sparkle errors

### Download failures

- Verify the DMG URL in the appcast is correct and accessible
- Check the file size and checksum match the actual DMG

### Workflow failures

- Check GitHub Actions logs for detailed error messages
- Verify that the DMG is available before the appcast/cask update workflows run
- Check network connectivity if downloads are failing

## Security Considerations

- The appcast feed is served over HTTPS from GitHub
- DMG files are downloaded from GitHub Releases (HTTPS)
- Sparkle verifies file integrity using SHA256 checksums
- Network access is required and granted via entitlements

## Future Enhancements

Potential improvements to the update system:

- Code signing for notarized updates
- Delta updates for smaller download sizes
- More granular update channels (stable, beta, nightly)
- Release notes rendering in the update prompt
