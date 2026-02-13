# CONCERNS.md - Technical Debt and Areas of Concern

## Overview

This document tracks technical debt, known issues, fragile areas, and potential improvements for the Oak focus companion app.

---

## High Priority Concerns

### 1. Missing UserDefaults Isolation in Tests

**Location**: `PresetSettingsStore`, `ProgressManager`, `UpdateChecker`

**Issue**: Several classes use `UserDefaults.standard` by default, which can cause test pollution when tests run in parallel or share the same process.

**Impact**: Tests may interfere with each other; flaky tests; local machine state pollution.

**Example**:

```swift
// ProgressManager.swift:10
init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    loadProgress()
}
```

**Mitigation**: Tests should always inject custom `UserDefaults` instances with unique suite names.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/ProgressManager.swift`
- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/PresetSettingsStore.swift`
- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/UpdateChecker.swift`

---

### 2. Fragile Frame Update Logic in NotchWindowController

**Location**: `NotchWindowController.setExpanded()` and frame update coordination

**Issue**: Multiple state flags (`isApplyingFrameChange`, `isFrameUpdateScheduled`, `pendingExpandedState`, `pendingForceReposition`) coordinate frame updates. This complex state machine is prone to race conditions, especially during rapid expansion/collapse or screen configuration changes.

**Impact**: Window may misposition; window may not expand/collapse correctly; visual jank.

**Example**:

```swift
// NotchWindowController.swift:138
guard !isApplyingFrameChange else { return }
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchWindowController.swift`

---

### 3. Hardcoded Repository Owner/Name in UpdateChecker

**Location**: `UpdateChecker.init()`

**Issue**: Default parameters use hardcoded `"jellydn"` and `"oak"`. This is fragile for forks and may not match actual repository.

**Impact**: Update checks may fail or point to wrong repository.

**Example**:

```swift
// UpdateChecker.swift:19-20
init(
    repositoryOwner: String = "jellydn",
    repositoryName: String = "oak",
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/UpdateChecker.swift`

---

## Medium Priority Concerns

### 4. Global Singletons Used as Dependencies

**Location**: `NotificationService.shared`, `PresetSettingsStore.shared`

**Issue**: Direct use of singletons (`NotificationService.shared`) creates implicit dependencies and makes testing difficult. While some constructors accept injected dependencies, the singleton shortcuts remain.

**Impact**: Tighter coupling; harder to test in isolation; potential shared state issues.

**Example**:

```swift
// NotchCompanionView.swift:8
@StateObject private var notificationService = NotificationService.shared
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/NotificationService.swift`
- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchCompanionView.swift`

---

### 5. Display Target Fallback Complexity

**Location**: `NSScreen+DisplayTarget.screen()`

**Issue**: The screen resolution logic has multiple fallback paths (preferredDisplayID -> primary -> secondary -> notched -> primary). This complexity makes behavior unpredictable when displays are disconnected or reconfigured.

**Impact**: Window may appear on wrong display; confusing behavior in multi-monitor setups.

**Example**:

```swift
// NSScreen+DisplayTarget.swift:48-51
return secondaryScreen(excluding: primary)
    ?? notchedScreen()
    ?? primary
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Extensions/NSScreen+DisplayTarget.swift`

---

### 6. Timer Memory Management in FocusSessionViewModel

**Location**: `FocusSessionViewModel.startTimer()`

**Issue**: Timer is created with `[weak self]` but the callback captures `self` strongly via `Task { @MainActor in self?.tick() }`. While this avoids retain cycles, the cleanup logic relies on proper `deinit` or explicit `cleanup()` calls.

**Impact**: Potential for timer fires after deallocation; crashes if not cleaned up properly.

**Example**:

```swift
// FocusSessionViewModel.swift:246-250
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        self?.tick()
    }
}
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/ViewModels/FocusSessionViewModel.swift`

---

### 7. Audio Engine Node Taps Not Cleaned Up Consistently

**Location**: `AudioManager.stop()`

**Issue**: The `stop()` method removes taps from `audioNodes` but nodes created via `AVAudioSourceNode` may not have taps registered. This is defensive but inconsistent.

**Impact**: Minor potential for resource leaks; unclear if needed.

**Example**:

```swift
// AudioManager.swift:47
audioNodes.forEach { $0.removeTap(onBus: 0) }
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/AudioManager.swift`

---

## Low Priority Concerns

### 8. Typo in Property Wrapper

**Location**: `SettingsMenuView`

**Issue**: `@ObservedObject` is misspelled as `@ObservedObject` (missing 'r') in property declarations. Swift currently accepts this due to compiler leniency but it's incorrect.

**Impact**: Code is less readable; may break with future Swift versions.

**Example**:

```swift
// SettingsMenuView.swift:5-6
@ObservedObject var presetSettings: PresetSettingsStore
@ObservedObject var notificationService: NotificationService
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/SettingsMenuView.swift`

---

### 9. Typo in Settings Preference Key

**Location**: `OakApp.swift`

**Issue**: `.accessory` is misspelled in activation policy setting. The correct enum value is `.accessory`.

**Impact**: App may not activate correctly; potential runtime issues.

**Example**:

```swift
// OakApp.swift:37
NSApp.setActivationPolicy(.accessory)
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/OakApp.swift`

---

### 10. Typo in Switch Statement

**Location**: `SettingsMenuView.notificationStatusText`

**Issue**: `.denied` is misspelled in switch statement; should be `.denied`.

**Impact**: Notifications denied case may not be handled correctly.

**Example**:

```swift
// SettingsMenuView.swift:333
case .denied:
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/SettingsMenuView.swift`

---

### 11. Typo in Font Design

**Location**: `NotchCompanionView`

**Issue**: `.monospaced` is misspelled as `.monospaced` (missing 'c').

**Impact**: Fallback to default font; monospace alignment may not work.

**Example**:

```swift
// NotchCompanionView.swift:242
.font(.system(size: fontSize, weight: .semibold, design: .monospaced))
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchCompanionView.swift`

---

### 12. Typo in Capsule Shape

**Location**: `NotchCompanionView.presetSelector`

**Issue**: `Capsule` is misspelled as `Capsule` (missing 'u').

**Impact**: May fail to compile or use fallback shape.

**Example**:

```swift
// NotchCompanionView.swift:460
Capsule(style: .continuous)
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchCompanionView.swift`

---

### 13. Incomplete Error Handling in UpdateChecker

**Location**: `UpdateChecker.checkForUpdates()`

**Issue**: Network errors are logged but silently swallowed. Users have no visibility into update check failures.

**Impact**: Poor user experience when updates are available but check fails.

**Example**:

```swift
// UpdateChecker.swift:81-83
} catch {
    logger.error("Update check failed: \(error.localizedDescription, privacy: .public)")
}
```

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/UpdateChecker.swift`

---

### 14. ProgressManager Streak Calculation Complexity

**Location**: `ProgressManager.calculateStreak()`

**Issue**: The streak calculation algorithm is manually implemented with date comparisons. This is fragile to timezone changes and calendar edge cases.

**Impact**: Streaks may be calculated incorrectly; confusing UX.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/ProgressManager.swift`

---

### 15. No Validation for DisplayID Persistence

**Location**: `PresetSettingsStore.ensureDisplayIDsInitialized()`

**Issue**: Display IDs are persisted but never invalidated. If a display is disconnected and reconnected, the old ID may be stale.

**Impact**: Window may not appear on correct display after reconfiguration.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/PresetSettingsStore.swift`

---

## Architecture Concerns

### 16. Mixed Responsibilities in NotchCompanionView

**Location**: `NotchCompanionView`

**Issue**: The view manages its own expansion state (`isExpandedByToggle`) while also delegating to `NotchWindowController` via `onExpansionChanged`. This dual responsibility can cause state desynchronization.

**Impact**: Visual glitches; state inconsistency; hard to debug.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchCompanionView.swift`

---

### 17. Global State via UserDefaults

**Location**: Multiple persistence stores

**Issue**: Heavy reliance on `UserDefaults` without abstraction layer. Makes testing harder and limits future migration to other persistence mechanisms.

**Impact**: Difficult to change persistence; tests require cleanup; potential data migration issues.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/ProgressManager.swift`
- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/PresetSettingsStore.swift`
- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/UpdateChecker.swift`

---

## Performance Concerns

### 18. Potential Audio Generation CPU Usage

**Location**: `AudioManager` noise generation

**Issue**: Real-time noise generation via `AVAudioSourceNode` may use significant CPU, especially with multiple tracks. No throttling or sample rate limiting is evident.

**Impact**: Battery drain on laptops; thermal throttling.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/AudioManager.swift`

---

### 19. No Lazy Loading for Settings Popover

**Location**: `NotchCompanionView.settingsMenu` popover

**Issue**: `SettingsMenuView` is instantiated immediately when settings popover is shown, not before. This could cause slight UI lag.

**Impact**: Minor UX delay when opening settings.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Views/NotchCompanionView.swift`

---

## Security Concerns

### 20. No Input Validation for User Settings

**Location**: `PresetSettingsStore` setters

**Issue**: While validation methods exist (`validatedWorkMinutes`, etc.), UserDefaults values are read without validation. Corrupted preferences could cause unexpected behavior.

**Impact**: App may crash or behave unexpectedly with corrupted preferences.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/PresetSettingsStore.swift`

---

### 21. GitHub API Rate Limiting

**Location**: `UpdateChecker`

**Issue**: No authentication token for GitHub API requests. Subject to stricter rate limits (60 requests/hour vs 5000/hour authenticated).

**Impact**: Update checks may fail in active development or frequent launches.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/UpdateChecker.swift`

---

## Testing Concerns

### 22. Test-Only Methods Exposed on Production Classes

**Location**: `FocusSessionViewModel.completeSessionForTesting()`

**Issue**: Test-only methods pollute production API. While convenient for testing, they increase surface area and potential misuse.

**Impact**: Larger API surface; potential for accidental misuse.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/ViewModels/FocusSessionViewModel.swift`

---

### 23. Limited Test Coverage for Audio

**Issue**: No visible tests for `AudioManager` or `NoiseGenerator`. Audio generation is complex and error-prone.

**Impact**: Potential audio bugs; regressions in sound generation.

**Files**:

- `/Users/huynhdung/src/tries/2026-02-12-oak/Oak/Oak/Services/AudioManager.swift`

---

## Documentation Concerns

### 24. Missing Inline Documentation

**Issue**: Many public APIs lack `///` documentation comments. While code is generally self-documenting, complex algorithms (streak calculation, frame updates) would benefit from explanation.

**Impact**: Harder for new contributors; unclear intent.

---

## Summary

| Category        | Count |
| --------------- | ----- |
| High Priority   | 3     |
| Medium Priority | 5     |
| Low Priority    | 12    |
| Architecture    | 2     |
| Performance     | 2     |
| Security        | 2     |
| Testing         | 2     |
| Documentation   | 1     |

**Total**: 29 documented concerns

---

## Maintenance Notes

- Review this document quarterly
- Address high-priority items before each major release
- Update this document when new concerns are identified or resolved
- Consider creating ADRs (Architecture Decision Records) for significant refactoring decisions
