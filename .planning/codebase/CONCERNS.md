# CONCERNS.md — Technical Debt & Areas of Concern

## File Size & Complexity

| Concern | Severity | Detail |
| --- | --- | --- |
| **FocusSessionViewModel.swift (415 lines)** | Medium | Largest file in the codebase. Handles session FSM, timer management, auto-start countdown, audio coordination, progress recording, and notification triggering. Could benefit from extraction of timer/countdown logic into a separate service. |
| **AudioManager.swift (374 lines)** | Low | Mixes bundled audio playback, procedural noise generation, and audio engine lifecycle. `NoiseGenerator` is in the same file. |
| **SettingsMenuView.swift (334 lines)** | Low | Comprehensive settings view with many sections. Already well-structured with separate sub-views but remains a large file. |

## Architectural Observations

| Concern | Severity | Detail |
| --- | --- | --- |
| **Single ViewModel** | Low | Only `FocusSessionViewModel` exists in `ViewModels/`. As features grow, extracting specialized ViewModels (e.g., `SettingsViewModel`, `ProgressViewModel`) would improve separation. |
| **NoiseGenerator on Audio Thread** | Low | `NoiseGenerator` is marked `@unchecked Sendable` and runs on the audio render thread. State mutation is careful but the `@unchecked` Sendable conformance bypasses compiler safety checks. |
| **Timer callbacks use Task { @MainActor }** | Info | This is the established pattern but adds an extra async hop per tick. Consider using `Timer.publish(every:on:in:)` with Combine for direct main-thread delivery. |

## Testing

| Concern | Severity | Detail |
| --- | --- | --- |
| **Some test files are thin** | Low | `ConfettiViewTests.swift` (16 lines), `ClickOutsideModifierTests.swift` (23 lines), and `SmokeTests.swift` (7 lines) have minimal test coverage. Other previously-thin files (`SparkleUpdaterTests` at 85 lines, `AppcastVersionParserTests` at 86 lines, `NSScreenNotchTests` at 167 lines) have been filled out. |
| **No UI/integration tests** | Low | All tests are unit tests. No automated UI testing for notch positioning, window behavior, or visual states. |

## Code Style

| Concern | Detail |
| --- | --- |
| Pre-existing format issues were resolved in a prior commit (`docs: mark pre-existing format issues as resolved in CONCERNS.md`). No known format violations remain. | — |

## Potential Improvements

1. **Extract timer service**: Move timer/countdown logic from `FocusSessionViewModel` into a dedicated `SessionTimerService` to reduce ViewModel size.
2. **Extract NoiseGenerator**: Move `NoiseGenerator` to its own file under `Services/`.
3. **Add UI snapshot tests**: Use SwiftUI previews or snapshot testing for notch layout variants (inside-notch, below-notch, collapsed, expanded).
4. **Consider `Timer.publish`**: Replace `Timer.scheduledTimer` with Combine's `Timer.publish` for direct main-thread timer delivery.
5. **Expand remaining thin test files**: Add meaningful assertions to `ConfettiViewTests` (16 lines), `ClickOutsideModifierTests` (23 lines), and `SmokeTests` (7 lines).

## None Detected

- **Security vulnerabilities**: No known security issues. App is sandbox-eligible with only `network.client` entitlement.
- **Performance regressions**: No identified performance issues.
- **Memory leaks**: Timer and Combine cleanup patterns appear correct with `invalidate()` and `cancel()` in `deinit`.
- **Breakage risk**: No fragile areas identified beyond the single large ViewModel file.
