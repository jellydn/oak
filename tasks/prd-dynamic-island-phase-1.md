# PRD: Dynamic Island-Like Notch Experience (Phase 1)

## 1. Introduction/Overview

Oak currently provides a notch-based focus companion UI, but it does not yet feel like a Dynamic Island-style surface.  
This phase adds Dynamic Island-like behavior and polish while keeping the implementation simple (KISS): top-notch placement on the main monitor, smooth expansion/collapse interactions, and consistent motion behavior.

## 2. Goals

- Make the notch UI feel Dynamic Island-like in behavior and visual rhythm.
- Keep the window pinned to the top-center of the main monitor by default.
- Support hover-based expansion and idle collapse with predictable transitions.
- Deliver a focused, low-risk improvement without adding new modules/features.

## 3. User Stories

### US-001: Main-Monitor Top Anchor by Default
**Description:** As a user, I want Oak to appear on my main monitor at the top center so the notch UI always opens where I expect.

**Acceptance Criteria:**
- [ ] Window defaults to `NSScreen.main` when available.
- [ ] Window frame is anchored to top-center of selected screen using absolute screen coordinates.
- [ ] On screen parameter changes, window repositions without requiring expand/collapse state change.
- [ ] `just build` passes.
- [ ] `just lint` passes.

### US-002: Hover-to-Expand Interaction
**Description:** As a user, I want the notch UI to expand when I hover so I can quickly access content without clicking.

**Acceptance Criteria:**
- [ ] Hovering over collapsed notch enters expanded state.
- [ ] Expansion starts within defined response threshold (e.g., <=150ms after hover intent).
- [ ] Repeated hover events while already expanded do not cause duplicate/stacked transitions.
- [ ] `just build` passes.
- [ ] `just lint` passes.
- [ ] Verify in browser using dev-browser skill (N/A for macOS; verify directly in running app).

### US-003: Idle Auto-Collapse
**Description:** As a user, I want the notch UI to collapse automatically after inactivity so it stays unobtrusive.

**Acceptance Criteria:**
- [ ] Expanded state collapses after configurable idle timeout for phase 1 default (fixed value in code).
- [ ] User interaction inside expanded content resets idle timer.
- [ ] Collapse timer is canceled/cleaned up when window/controller is deinitialized.
- [ ] `just build` passes.
- [ ] `just lint` passes.
- [ ] Verify in browser using dev-browser skill (N/A for macOS; verify directly in running app).

### US-004: Motion Consistency and Stability
**Description:** As a user, I want transitions to feel smooth and consistent so the UI feels intentional rather than jumpy.

**Acceptance Criteria:**
- [ ] Expand/collapse uses one consistent animation profile (duration + easing).
- [ ] Position remains top-anchored during width changes.
- [ ] No visible flicker or frame jumping during rapid hover in/out cycles.
- [ ] `just build` passes.
- [ ] `just lint` passes.
- [ ] Verify in browser using dev-browser skill (N/A for macOS; verify directly in running app).

## 4. Functional Requirements

- FR-1: The system must use `NSScreen.main` as the default monitor target whenever it is available.
- FR-2: The notch window must be positioned at top-center of the chosen monitor using that screen’s absolute frame origin and dimensions.
- FR-3: The system must support hover-triggered transition from collapsed to expanded state.
- FR-4: The system must support automatic collapse after inactivity timeout when expanded.
- FR-5: The system must reset inactivity timer on relevant user interaction inside expanded UI.
- FR-6: The system must avoid redundant frame/animation updates when requested state equals current state.
- FR-7: On display configuration changes, the system must recompute and apply valid top-center frame on the chosen monitor.
- FR-8: Animation timing and easing must be unified across expand/collapse transitions.

## 5. Non-Goals (Out of Scope)

- Media controls, now-playing modules, or audio transport widgets.
- Notification/live activity integrations beyond current Oak scope.
- File shelf, drag-and-drop tray, AirDrop helpers, or clipboard dock.
- Per-monitor preference UI or advanced monitor routing policies.
- Full feature parity with third-party notch apps.

## 6. Design Considerations

- Visual language should feel Dynamic Island-like while preserving Oak branding and existing component structure.
- Expanded and collapsed states should maintain clear shape continuity (avoid abrupt geometry changes).
- Motion should feel responsive but calm; avoid overly bouncy or distracting effects.

## 7. Technical Considerations

- Keep changes localized to notch window controller/view interaction boundaries.
- Maintain MVVM + `@MainActor` patterns for UI-facing logic.
- Ensure timers/observers are cleaned up properly to avoid leaks and stale callbacks.
- Preserve existing notch-only constraints and MVP rules.

## 8. Success Metrics

- 100% of launches place the notch UI on main monitor top-center when `NSScreen.main` exists.
- Hover-to-expanded response is consistently within target threshold (<=150ms).
- Idle auto-collapse occurs consistently after the configured timeout with no stuck expanded state.
- No build/lint regressions in CI-equivalent local checks.

## 9. Open Questions

- Resolved: Phase 1 idle timeout is `1.0s`.
- Resolved: Hover expansion uses a small intent delay to reduce accidental expansion.
- Resolved: Phase 2 should include an optional click-to-pin expanded state.
