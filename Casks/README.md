# Homebrew Cask for Oak

This directory contains the Homebrew Cask formula for Oak.

## Installation

To install Oak using Homebrew:

```bash
# Add the tap
brew tap jellydn/oak https://github.com/jellydn/oak

# Install Oak
brew install --cask oak
```

## Automatic Updates

The cask formula is automatically updated when:
- A new GitHub Release is published
- A version tag (e.g., `v0.4.2`) is pushed to the repository

This is handled by the `.github/workflows/update-homebrew.yml` workflow.

## Manual Updates

If you need to manually trigger an update (e.g., for a release that was published before the workflow was added):

1. Go to the [Update Homebrew Cask workflow](https://github.com/jellydn/oak/actions/workflows/update-homebrew.yml)
2. Click "Run workflow"
3. Enter the tag name (e.g., `v0.4.2`)
4. Click "Run workflow"

Alternatively, you can manually update the cask file:

1. Update the `version` field to match the new release tag (without the 'v' prefix)
2. Download the DMG from the release
3. Calculate the SHA256: `shasum -a 256 Oak-x.y.z.dmg`
4. Update the `sha256` field in the cask formula
5. Commit and push the changes

## Submitting to Homebrew Cask

To submit Oak to the official Homebrew Cask repository:

1. Ensure the cask formula follows [Homebrew Cask guidelines](https://docs.brew.sh/Cask-Cookbook)
2. Test the cask: `brew install --cask ./Casks/oak.rb`
3. Submit a PR to [homebrew-cask](https://github.com/Homebrew/homebrew-cask)

For now, users can tap this repository directly to install Oak.
