# Codebase Structure

**Analysis Date:** 2026-02-13

## Directory Layout

```
Oak/ (Xcode project root)
├── Oak/ # Main application target source
│   ├── Models/ # Domain data types and enums
│   ├── Views/ # SwiftUI views and window management
│   ├── ViewModels/ # MVVM view models and business logic
│   ├── Services/ # Business logic, persistence, external integrations
│   ├── Extensions/ # Utility extensions on system types
│   ├── Resources/ # Assets, sounds, configuration (optional)
│   └── OakApp.swift # App entry point
├── Tests/ # Test bundles
│   └── OakTests/ # Unit tests
├── Oak.xcodeproj/ # Generated Xcode project
├── project.yml # XcodeGen configuration
├── justfile # Just command runner
├── .swiftlint.yml # SwiftLint configuration
├── .swiftformat # SwiftFormat configuration
└── .github/ # CI/CD workflows
```

## Directory Purposes

**Oak/Oak/Models:**
- Purpose: Domain models, value objects, enums, and data structures
- Contains: Session state machine, preset configurations, display targets, audio tracks, progress tracking, layout constants
- Key files: `SessionModels.swift` (SessionState, Preset, DisplayTarget), `AudioTrack.swift`, `ProgressData.swift`, `NotchLayout.swift`, `CountdownDisplayMode.swift`

**Oak/Oak/Views:**
- Purpose: SwiftUI UI components and NSWindow/NSPanel management
- Contains: Main notch view, settings menu, audio menu, progress menu, window controller, custom UI components (progress ring, confetti)
- Key files: `NotchCompanionView.swift`, `NotchWindowController.swift`, `SettingsMenuView.swift`, `AudioMenuView.swift`, `ProgressMenuView.swift`, `CircularProgressRing.swift`, `ConfettiView.swift`

**Oak/Oak/ViewModels:**
- Purpose: MVVM view models coordinating business logic and state
- Contains: Focus session state machine, timer management, progress tracking coordination
- Key files: `FocusSessionViewModel.swift`

**Oak/Oak/Services:**
- Purpose: Business logic, persistence, and external system integrations
- Contains: Audio playback, system notifications, progress tracking/persistence, update checking, settings persistence
- Key files: `AudioManager.swift`, `NotificationService.swift`, `ProgressManager.swift`, `UpdateChecker.swift`, `PresetSettingsStore.swift`

**Oak/Oak/Extensions:**
- Purpose: Utility extensions on Apple frameworks
- Contains: NSScreen extensions for multi-display support
- Key files: `NSScreen+DisplayTarget.swift`

**Oak/Tests/OakTests:**
- Purpose: Unit tests and integration tests
- Contains: Smoke tests, user story tests (US001-US006), component tests, long break tests
- Key files: `SmokeTests.swift`, `US001Tests.swift` through `US006Tests.swift`, `LongBreakTests.swift`, component-specific tests

## Key File Locations

**Entry Points:**
- `Oak/Oak/OakApp.swift`: Application entry point (@main), app delegate
- `Oak/Oak/Views/NotchWindowController.swift`: Window management for notch UI

**Configuration:**
- `Oak/project.yml`: XcodeGen project configuration (targets, sources, settings)
- `Oak/.swiftlint.yml`: SwiftLint rules and opt-in rules
- `Oak/.swiftformat`: SwiftFormat formatting configuration
- `Oak/justfile`: Just command runner for build/test/lint commands

**Core Logic:**
- `Oak/Oak/ViewModels/FocusSessionViewModel.swift`: Focus session state machine, timer, session lifecycle
- `Oak/Oak/Services/PresetSettingsStore.swift`: Settings persistence, validation, defaults
- `Oak/Oak/Services/AudioManager.swift`: Audio playback (bundled files and generated)
- `Oak/Oak/Services/ProgressManager.swift`: Daily progress tracking, streak calculation, persistence
- `Oak/Oak/Services/NotificationService.swift`: System notifications, authorization management

**Testing:**
- `Oak/Tests/OakTests/SmokeTests.swift`: Basic smoke tests
- `Oak/Tests/OakTests/US001Tests.swift` through `US006Tests.swift`: User story tests
- `Oak/Tests/OakTests/LongBreakTests.swift`: Long break cycle tests
- `Oak/Tests/OakTests/ComponentNameTests.swift`: Component-specific tests

## Naming Conventions

**Files:**
- `{Feature}View.swift`: SwiftUI views (e.g., `SettingsMenuView.swift`, `AudioMenuView.swift`)
- `{Feature}ViewModel.swift`: ViewModels (e.g., `FocusSessionViewModel.swift`)
- `{Feature}Manager.swift`: Services managing external resources (e.g., `AudioManager.swift`, `ProgressManager.swift`)
- `{Feature}Store.swift`: Persistence stores (e.g., `PresetSettingsStore.swift`)
- `{Feature}Service.swift`: Business logic services (e.g., `NotificationService.swift`)
- `{ModelName}Models.swift`: Grouped model types (e.g., `SessionModels.swift`)
- `{Type}+{Feature}.swift`: Extensions on system types (e.g., `NSScreen+DisplayTarget.swift`)

**Directories:**
- `Models/`: Data types, enums, structs
- `Views/`: SwiftUI views, window management
- `ViewModels/`: MVVM view models
- `Services/`: Business logic, persistence, external integrations
- `Extensions/`: Type extensions
- `Resources/`: Assets, sounds, configuration

**Types:**
- Enums: PascalCase with lowerCamelCase cases (e.g., `SessionState`, `DisplayTarget.mainDisplay`)
- Classes: PascalCase (e.g., `FocusSessionViewModel`, `NotchWindowController`)
- Structs: PascalCase (e.g., `ProgressData`, `DailyStats`)
- Protocols: PascalCase ending in type/category (e.g., `SessionCompletionNotifying`, `UpdateChecking`)
- Functions: lowerCamelCase (e.g., `startSession()`, `setWorkMinutes()`)
- Constants: lowerCamelCase for instance, PascalCase for static

**Tests:**
- `SmokeTests.swift`: Basic smoke tests
- `US{N}Tests.swift`: User story tests (e.g., `US001Tests.swift`, `US004Tests.swift`)
- `{Component}Tests.swift`: Component-specific tests (e.g., `NotificationTests.swift`, `LongBreakTests.swift`)

## Where to Add New Code

**New Feature:**
- Primary code: `Oak/Oak/ViewModels/` (if state management needed) or `Oak/Oak/Services/` (if pure business logic)
- Tests: `Oak/Tests/OakTests/{Feature}Tests.swift` or `Oak/Tests/OakTests/US{N}Tests.swift` (user story)

**New UI View:**
- Implementation: `Oak/Oak/Views/{Feature}View.swift`
- View model: `Oak/Oak/ViewModels/{Feature}ViewModel.swift` (if needed)
- Tests: `Oak/Tests/OakTests/{Feature}ViewTests.swift`

**New Service:**
- Implementation: `Oak/Oak/Services/{Feature}Service.swift` or `{Feature}Manager.swift` or `{Feature}Store.swift`
- Protocol: Define protocol with `{Feature}Service` suffix for testability
- Tests: `Oak/Tests/OakTests/{Feature}Tests.swift`

**New Model/Enum:**
- Implementation: `Oak/Oak/Models/{Feature}Models.swift` (grouped) or `{ModelName}.swift` (standalone)

**Utilities:**
- Shared helpers: `Oak/Oak/Extensions/` (extending system types) or `Oak/Oak/Services/` (standalone utilities)

## Special Directories

**Oak/Oak/Resources:**
- Purpose: Assets, sounds, configuration files
- Generated: No
- Committed: Yes
- Contains: Ambient audio files (optional - falls back to generated audio), AppIcon assets

**Oak/Oak.xcodeproj:**
- Purpose: Xcode project file (generated by XcodeGen)
- Generated: Yes
- Committed: Yes
- Regenerate with: `cd Oak && xcodegen generate` or `just open`

**Oak/.build:**
- Purpose: Build artifacts, intermediate build files
- Generated: Yes
- Committed: No
- In .gitignore: Yes

**Oak/.github/workflows:**
- Purpose: CI/CD workflows
- Generated: No
- Committed: Yes
- Contains: GitHub Actions workflows

---

*Structure analysis: 2026-02-13*
