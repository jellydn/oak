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

The cask formula is automatically updated when a new release is published via the `.github/workflows/update-homebrew.yml` workflow.

## Manual Updates

If you need to manually update the cask:

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
