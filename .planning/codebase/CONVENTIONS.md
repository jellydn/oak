# CONVENTIONS.md — Coding Standards & Patterns

## Formatting

| Rule             | Value                          |
| ---------------- | ------------------------------ |
| Indentation      | 4 spaces                       |
| Line length      | 120 (warn), 150 (error)        |
| File length      | 500 lines (warn), 1000 (error) |
| Function body    | 50 lines (warn)                |
| Trailing newline | Required                       |
| Documentation    | `///` for public/internal APIs |

## Naming

| Element | Convention | Example |
| --- | --- | --- |
| Types | PascalCase | `FocusSessionViewModel` |
| Functions/Vars | camelCase | `startSession()`, `displayTime` |
| Constants (instance) | lowerCamelCase | `horizontalPadding` |
| Constants (static) | PascalCase | `minWorkMinutes` |
| Booleans | `is`/`has`/`should`/`can` prefix | `isWorkSession`, `canStart`, `shouldUseLongBreak` |
| Protocols (capability) | `*ing` suffix | `SessionCompletionNotifying` |
| Protocols (role) | `*Protocol` suffix | `AudioEngineProtocol` |
| UserDefaults keys | dot-notation strings | `"preset.short.workMinutes"` |

## Access Control

- `internal` keyword is **explicit** on ALL declarations (SwiftLint `explicit_top_level_acl`)
- `private` for internal state, `private(set)` for read-only published
- `private enum Keys` with static strings for UserDefaults keys

## Imports

```swift
// Order: Foundation → Combine → SwiftUI/AppKit → Apple frameworks
import Foundation
import Combine
import SwiftUI
import AVFoundation
```

- No blank lines between imports
- One blank line between types
- Remove unused imports (analyzer rule)

## ViewModel & ObservableObject Patterns

```swift
@MainActor
internal class FocusSessionViewModel: ObservableObject {
    @Published var sessionState: SessionState = .idle
    @Published var selectedPreset: Preset = .short
    @Published private(set) var completedRounds: Int = 0

    // Protocol-based DI
    let audioManager: AudioManager
    let notificationService: any SessionCompletionNotifying
    let completionSoundPlayer: any SessionCompletionSoundPlaying

    init(
        presetSettings: PresetSettingsStore,
        audioManager: AudioManager? = nil,
        notificationService: any SessionCompletionNotifying,
        completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) { ... }
}
```

- Always `@MainActor` on `ObservableObject` classes
- Use `any Protocol` for type-erased DI
- Provide default parameter values for optional dependencies
- Forward `objectWillChange` from child stores via Combine

## State Machine Pattern

```swift
// Enum with associated values for FSM
internal enum SessionState: Equatable {
    case idle
    case running(remainingSeconds: Int, isWorkSession: Bool)
    case paused(remainingSeconds: Int, isWorkSession: Bool)
    case completed(isWorkSession: Bool)
}

// State checks via if case
if case .idle = sessionState { ... }
if case let .running(remaining, isWork) = sessionState { ... }
```

## Error Handling & Logging

- `os.Logger` for production logging (subsystem: `com.productsway.oak.app`)
- No `print()` statements (SwiftLint warns)
- `guard` early returns preferred over nested `if`
- `Result` for async operations
- `do/catch` with logged errors for audio operations

## Memory & Concurrency

```swift
// [weak self] in ALL escaping closures
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        self?.tick()
    }
}

// Always invalidate() timers in deinit
deinit {
    timer?.invalidate()
    autoStartTimer?.invalidate()
}
```

- `[weak self]` in all escaping closures
- `Timer.invalidate()` in `deinit`
- `Task { @MainActor in ... }` to return to main actor
- `AnyCancellable` for Combine subscriptions, cancelled on deinit

## View Update Safety

```swift
// ❌ Wrong - publishes from view update synchronously
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct - async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

## Dependency Injection

Protocol-based DI is used throughout:

- `SessionCompletionNotifying` — notification delivery (mocked in tests)
- `SessionCompletionSoundPlaying` — completion sound (mocked in tests)
- `AudioEngineProtocol` — audio engine (mocked in tests)

Default implementations provided via init parameters for production use.

## UserDefaults

- Keys stored in `private enum Keys { static let ... }`
- `userDefaults.register(defaults:)` for all keys at init
- Validated getters with clamped ranges (`validatedWorkMinutes`, `validatedBreakMinutes`)
- Guard against no-op writes: `guard currentValue != newValue else { return }`

## SwiftUI View Conventions

- Extract subviews as `private var someView: some View` computed properties
- Use `@ObservedObject` for injected dependencies
- `@State` for local UI state only
- Popover-based menus (audio, progress, settings)
- Completion animations: `.spring(response: 0.3, dampingFraction: 0.7)`
