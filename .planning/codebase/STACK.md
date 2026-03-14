# Technology Stack

**Analysis Date:** 2026-03-14

## Languages

**Primary:**
- Swift 5.9+ - All application code
- YAML - Build configuration (XcodeGen)

**Secondary:**
- Shell - Build scripts and automation
- JSON - Configuration files (renovate.json)

## Runtime

**Environment:**
- Swift 5.9+ runtime
- macOS 13.0+ (Monterey)

**Package Manager:**
- Swift Package Manager (SPM)
- Lockfile: `Package.resolved` (in Oak directory)

## Frameworks

**Core:**
- SwiftUI - UI framework
- AVFoundation - Audio playback
- Combine - Reactive programming
- AppKit - macOS-specific UI (NSPanel, NSWindow)

**Testing:**
- XCTest - Unit testing framework
- XCTMetrics - Performance testing

**Build/Dev:**
- XcodeGen - Project generation from YAML
- Xcode 17.0 - IDE and build system

## Key Dependencies

**Critical:**
- Sparkle 2.6.4+ - Auto-update framework
  - Purpose: Handle app updates and version checking
  - Configuration: SPARKLE_PUBLIC_ED_KEY for signature verification

**Infrastructure:**
- None (built-in audio assets only)

## Configuration

**Environment:**
- No external environment variables required
- Configuration via UserDefaults with suite names
- Build settings in `project.yml`

**Build:**
- `project.yml` - XcodeGen configuration
- `Package.resolved` - SPM dependency pins
- `.swiftlint.yml` - Linting rules
- `Justfile` - Build automation

## Platform Requirements

**Development:**
- macOS 13.0+
- Xcode 17.0+
- XcodeGen (`brew install xcodegen`)
- SwiftLint (`brew install swiftlint`)
- SwiftFormat (`brew install swiftformat`)
- Just (`brew install just`)
- Apple Silicon required

**Production:**
- macOS 13.0+ (Monterey)
- Apple Silicon (arm64) only

---

*Stack analysis: 2026-03-14*
