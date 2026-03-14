# Codebase Concerns

**Analysis Date:** 2026-03-14

## Tech Debt

**Large Files:**
- Issue: Several files exceed 300 lines (FocusSessionViewModel: 360, AudioManager: 355, SettingsMenuView: 334)
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`, `Oak/Oak/Services/AudioManager.swift`, `Oak/Oak/Views/SettingsMenuView.swift`
- Impact: Harder to navigate and understand, may indicate need for refactoring
- Fix approach: Extract smaller types, use extensions to group related functionality

**View Extension Proliferation:**
- Issue: NotchCompanionView has multiple extensions (StandardViews, InsideNotch, Controls)
- Files: `Oak/Oak/Views/NotchCompanionView+*.swift`
- Impact: Makes it harder to find view logic
- Fix approach: Consider extracting separate view components

## Known Bugs

**None identified** - No open issues or FIXME comments found in analysis

## Security Considerations

**Sparkle Key:**
- Risk: EdDSA public key embedded in project.yml
- Files: `Oak/project.yml`
- Current mitigation: Key is public (verification only), private key held separately
- Recommendations: Ensure private key is properly secured in CI/CD

**Force Unwrapping:**
- Risk: Potential crashes if assumptions fail
- Files: Minimal use in codebase (SwiftLint rule checks for this)
- Current mitigation: SwiftLint warnings on force unwrapping
- Recommendations: Continue avoiding force unwrapping

## Performance Bottlenecks

**Timer Accuracy:**
- Problem: Timer-based countdown may drift over time
- Files: `Oak/Oak/Services/ProgressManager.swift`, `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- Cause: Timer intervals not guaranteed to be exact
- Improvement path: Use Date difference for actual elapsed time calculation

**Notch Detection:**
- Problem: Screen detection queries on every layout calculation
- Files: `Oak/Oak/Extensions/NSScreen+*.swift`
- Cause: No caching of screen detection results
- Improvement path: Cache notch detection result per screen session

## Fragile Areas

**Notch Layout Detection:**
- Files: `Oak/Oak/Extensions/NSScreen+DisplayTarget.swift`, `Oak/Oak/Views/NotchCompanionView+InsideNotch.swift`
- Why fragile: Relies on screen geometry heuristics that may break on future Macs
- Safe modification: Add detection for new Mac models in extensions
- Test coverage: Moderate - has dedicated tests but may not cover all hardware

**Audio Asset Loading:**
- Files: `Oak/Oak/Services/AudioManager.swift`
- Why fragile: Bundled assets must exist at specific paths
- Safe modification: Add validation script (`just check-sounds` exists)
- Test coverage: Has AudioPersistenceTests

## Scaling Limits

**File Size:**
- Current capacity: Bundled audio assets
- Limit: App bundle size (audio files take space)
- Scaling path: Would need external asset storage for more sounds

**Session Storage:**
- Current capacity: In-memory only
- Limit: No persistent session history
- Scaling path: Would need Core Data or file-based storage for history

## Dependencies at Risk

**Sparkle Framework:**
- Risk: External dependency for updates
- Impact: App won't auto-update if Sparkle breaks
- Migration plan: Consider native App Store distribution as alternative

## Missing Critical Features

**Session History:**
- Problem: No persistent record of completed sessions
- Blocks: Analytics, progress tracking, session review

**Custom Presets:**
- Problem: Can't create custom time presets
- Blocks: User personalization beyond 25/5 and 50/10

**Sync Across Devices:**
- Problem: No cloud sync for settings or progress
- Blocks: Multi-device usage

## Test Coverage Gaps

**Large File Coverage:**
- What's not tested: Some edge cases in 300+ line files
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift` (360 lines)
- Risk: Complex state transitions may have untested paths
- Priority: Medium - core session logic seems well covered

**Notch Geometry Tests:**
- What's not tested: All possible Mac screen configurations
- Files: `Oak/Oak/Extensions/NSScreen+*.swift`
- Risk: May fail on unreleased hardware
- Priority: Low - works on current hardware, easy to patch

**View Layout Tests:**
- What's not tested: Visual layout correctness (no snapshot tests)
- Files: `Oak/Oak/Views/*.swift`
- Risk: Layout regressions may go undetected
- Priority: Low - manual testing catches visual issues

---

*Concerns audit: 2026-03-14*
