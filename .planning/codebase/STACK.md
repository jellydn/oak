# Technology Stack

**Analysis Date:** 2026-02-15

## Languages
**Primary:**
- Swift 5.9+ - All application code (`Oak/Oak/**/*.swift`, `Oak/Tests/**/*.swift`)
**Secondary:**
- Shell/Bash - Build scripts (`scripts/`), CI workflows (`.github/workflows/*.yml`)
- Ruby - Homebrew cask formula (`Casks/oak.rb`)
- XML - Sparkle appcast feed (`appcast.xml`)

## Runtime
**Environment:**
- macOS 13.0+ (Ventura) - Minimum deployment target (`Oak/project.yml` line 14)
- Apple Silicon / x86_64 (universal macOS app)
**Package Manager:**
- Swift Package Manager (SPM) - Xcode-integrated dependency resolution
- Lockfile: present (`Oak/Oak.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`)

## Frameworks
**Core:**
- SwiftUI - Primary UI framework (`Oak/Oak/Views/*.swift`, `Oak/Oak/OakApp.swift`)
- AppKit - Window management, NSPanel, notifications (`Oak/Oak/Views/NotchWindowController.swift`)
- AVFoundation - Audio playback and procedural sound generation (`Oak/Oak/Services/AudioManager.swift`)
- Combine - Reactive state propagation (`Oak/Oak/ViewModels/FocusSessionViewModel.swift`)
- UserNotifications - macOS native notifications (`Oak/Oak/Services/NotificationService.swift`)
- CoreGraphics - Display/screen management (`Oak/Oak/Services/PresetSettingsStore.swift`)
**Testing:**
- XCTest - Unit tests (`Oak/Tests/OakTests/*.swift`)
**Build/Dev:**
- XcodeGen 17.0 - Project generation from `Oak/project.yml`
- xcodebuild - Build/test via Xcode toolchain (`justfile` lines 11-16)
- just - Task runner (`justfile`)
- SwiftLint - Linting (`.swiftlint.yml`)
- SwiftFormat - Code formatting (`.swiftformat`)

## Key Dependencies
**Critical:**
- Sparkle 2.8.1 (min 2.6.4) - Auto-update framework (`Oak/project.yml` line 8-9, `Package.resolved`)
  - Provides `SPUStandardUpdaterController`, EdDSA signature verification
  - Feed URL: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml`
**Infrastructure:**
- os.log (`Logger`) - Structured logging throughout services (`Oak/Oak/Services/*.swift`)

## Configuration
**Environment:**
- No `.env` files or environment variables required at runtime
- `SPARKLE_PUBLIC_ED_KEY` baked into build settings (`Oak/project.yml` line 28)
- `SPARKLE_PRIVATE_KEY` stored as GitHub Actions secret (CI-only, `update-appcast.yml` line 132)
- Build versioning derived from git tags (`justfile` line 3)
**Build:**
- `Oak/project.yml` - XcodeGen project definition
- `Oak/Oak/Info.plist` - App metadata, Sparkle feed config, LSUIElement (no dock icon)
- `Oak/Oak/Oak.entitlements` - Network client entitlement for update downloads
- `.swiftlint.yml` - Linter rules (120 char warning, 150 error)
- `.swiftformat` - Formatter rules (indent 4, maxwidth 120, LF line endings)
- `justfile` - Build/test/lint task definitions

## Platform Requirements
**Development:**
- macOS with Xcode 16+ (CI uses `macos-15` runner with `latest-stable` Xcode)
- Homebrew for SwiftLint (`brew install swiftlint`) and SwiftFormat (`brew install swiftformat`)
- just task runner (`brew install just`)
- XcodeGen for project regeneration (`just dev`)
**Production:**
- macOS 13.0+ (Ventura and later)
- Apple Silicon or Intel Mac with notch display (optimal UX)
- Network access for Sparkle update checks (`com.apple.security.network.client` entitlement)

---
*Stack analysis: 2026-02-15*
