# Troubleshooting Guide

This guide helps you resolve common issues when running Oak on macOS.

## "Oak Not Opened" - Gatekeeper Warning

When you first try to open Oak, you may see this error:

> **"Oak" Not Opened**  
> Apple could not verify "Oak" is free of malware that may harm your Mac or compromise your privacy.

### Why does this happen?

Oak is currently not signed with an Apple Developer certificate. macOS Gatekeeper blocks unsigned apps by default to protect your system. This is a standard security feature for apps downloaded from outside the Mac App Store.

### Solution Methods

Choose one of the following methods to run Oak:

#### Method 1: Open via System Settings (Recommended)

1. Try to open Oak normally (double-click the app)
2. Click **OK** or **Done** when the Gatekeeper warning appears
3. Open **System Settings** (or **System Preferences** on older macOS versions)
4. Navigate to **Privacy & Security**
5. Scroll down to the **Security** section
6. You should see a message: *"Oak was blocked from use because it is not from an identified developer"*
7. Click **Open Anyway**
8. Confirm your choice by clicking **Open** in the confirmation dialog

You only need to do this once. Oak will launch normally after this.

#### Method 2: Right-Click to Open

1. Locate the Oak app in Finder
2. **Right-click** (or **Control + Click**) on the Oak app
3. Select **Open** from the context menu
4. Click **Open** in the confirmation dialog that appears

This bypasses Gatekeeper for this specific app launch and future launches.

#### Method 3: Remove Quarantine Attribute (Terminal)

If you're comfortable with the command line:

```bash
# Navigate to where Oak.app is located (typically /Applications)
cd /Applications

# Remove the quarantine attribute
xattr -cr Oak.app
```

After running this command, you can open Oak normally.

### Why is Oak unsigned?

We don't currently have an Apple Developer account, which is required to sign macOS applications. Signing requires:
- An active Apple Developer Program membership ($99/year)
- Going through Apple's notarization process

We're working on obtaining proper code signing in the future. In the meantime, Oak is open source - you can review the code at [github.com/jellydn/oak](https://github.com/jellydn/oak) to verify its safety.

## Other Issues

### Oak won't start after updating

Try removing the app completely and reinstalling:

```bash
# If installed via Homebrew
brew uninstall --cask oak
brew install --cask oak

# If installed manually
# Delete Oak.app from /Applications and download fresh copy
```

### Audio not playing

1. Check that your system volume is not muted
2. Check Oak's audio settings - ensure an ambient sound is selected
3. Verify that other apps can play audio
4. Try restarting Oak

### Timer not appearing in notch

Oak requires a MacBook with a notch (14" or 16" MacBook Pro from 2021 or later). If you have a notch-equipped MacBook:

1. Ensure you're running macOS 13 (Ventura) or later
2. Try restarting Oak
3. Check that no other apps are using the notch area

### Settings not persisting

Oak stores settings locally using UserDefaults. If settings aren't saving:

1. Quit Oak completely
2. Check disk permissions for `~/Library/Preferences/`
3. Remove the preferences file and restart Oak:
   ```bash
   rm ~/Library/Preferences/com.productsway.Oak.plist
   ```

## Still Having Issues?

If you're still experiencing problems:

1. Check for existing issues: [github.com/jellydn/oak/issues](https://github.com/jellydn/oak/issues)
2. Open a new issue with:
   - Your macOS version
   - Steps to reproduce the problem
   - Any error messages or screenshots
   - Console logs if available (open Console.app and filter for "Oak")

## Building from Source

If you prefer to build Oak yourself to avoid Gatekeeper warnings:

1. See [DEVELOPMENT.md](DEVELOPMENT.md) for build instructions
2. Apps built locally are automatically trusted by macOS

---

*Last updated: February 2026*
