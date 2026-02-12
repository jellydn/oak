# PRD: macOS Focus Companion App (Oak)

## 1. Introduction/Overview

Build a lightweight, native macOS focus companion that helps users start deep work quickly and sustain attention through simple timed sessions and ambient reinforcement.

This PRD defines a KISS MVP focused on a notch-based experience with minimal setup, low system overhead, and no dashboard-style complexity.

## 2. Goals

- Enable users to start a focus session in 2 seconds or less.
- Deliver reliable fixed-structure work/break cycles with clear state transitions.
- Provide ambient audio support that improves immersion without UI clutter.
- Keep runtime footprint low enough to feel invisible during daily work.
- Track only minimal progress signals (daily total, session count, 7-day streak).

## 3. User Stories

### US-001: Start a focus session from the notch companion
**Description:** As a deep-work user, I want to start a session from the notch UI so that I can begin focusing without opening a full app window.

**Acceptance Criteria:**
- [ ] Notch companion is visible and interactive when app is running.
- [ ] One primary action starts a 25-minute focus session.
- [ ] Session state changes to running within 500 ms of user click.
- [ ] Typecheck/lint passes.

### US-002: Run fixed Pomodoro presets
**Description:** As a user, I want fixed presets so that I can follow a simple, repeatable routine without configuration overhead.

**Acceptance Criteria:**
- [ ] MVP supports only two presets: 25/5 and 50/10.
- [ ] Users can switch preset before session start.
- [ ] Work and break durations follow selected preset exactly.
- [ ] Typecheck/lint passes.

### US-003: Pause and resume active sessions
**Description:** As a user, I want pause/resume controls so that I can handle unavoidable interruptions without losing progress.

**Acceptance Criteria:**
- [ ] Active session can be paused and resumed from notch companion.
- [ ] Remaining time is preserved exactly across pause/resume.
- [ ] UI clearly indicates paused vs running state.
- [ ] Typecheck/lint passes.

### US-004: Play ambient sound during sessions
**Description:** As a user, I want ambient sound while focusing so that I can reduce distraction and maintain flow.

**Acceptance Criteria:**
- [ ] Built-in tracks available: rain, forest, cafe, brown noise, lo-fi.
- [ ] User can select one track before or during session.
- [ ] User can adjust volume from app controls.
- [ ] Audio stops automatically when session ends.
- [ ] Typecheck/lint passes.

### US-005: Receive lightweight session-complete feedback
**Description:** As a user, I want subtle completion feedback so that finishing a session feels rewarding without being disruptive.

**Acceptance Criteria:**
- [ ] Session completion triggers a short notch animation.
- [ ] Completion feedback does not steal keyboard focus.
- [ ] Next state (break or idle) is clearly shown.
- [ ] Typecheck/lint passes.

### US-006: View minimal personal progress
**Description:** As a user, I want minimal tracking so that I can stay motivated without being overwhelmed by analytics.

**Acceptance Criteria:**
- [ ] App stores daily focus minutes.
- [ ] App stores daily completed work session count.
- [ ] App computes and shows current 7-day streak.
- [ ] Data persists across app relaunch.
- [ ] Typecheck/lint passes.

## 4. Functional Requirements

- FR-1: The system must support macOS 13+ on Apple Silicon.
- FR-2: The system must provide a notch-only UI surface for v1 (no required standard main window workflow).
- FR-3: The system must allow one-click start of a default 25-minute focus session.
- FR-4: The system must support fixed presets only: 25/5 and 50/10.
- FR-5: The system must provide pause and resume actions for an active session.
- FR-6: The system must display remaining time continuously during an active session.
- FR-7: The system must provide optional auto-start of next interval (work <-> break), default OFF in MVP.
- FR-8: The system must not require any global keyboard shortcut in MVP.
- FR-9: The system must include built-in ambient tracks: rain, forest, cafe, brown noise, lo-fi.
- FR-10: The system must provide user volume control for ambient audio.
- FR-11: The system must stop ambient audio automatically when a session ends.
- FR-12: The system must trigger a subtle completion animation in the notch UI.
- FR-13: The system must persist session history locally and expose daily focus minutes, completed work sessions, and a 7-day streak based on completed work sessions only.
- FR-14: The system must not require account creation, cloud sync, or online connectivity for core MVP functionality.
- FR-15: The system must keep launch time under 1 second on supported devices in release builds.
- FR-16: The system must target CPU usage under 3% while idle in release builds.

## 5. Non-Goals (Out of Scope)

- Any distraction control in MVP (no macOS Focus mode trigger, no notification silencing controls).
- Custom timer durations.
- Additional or user-imported sound packs.
- Cross-device sync.
- Shared focus rooms or multiplayer features.
- CLI integration.
- Team/workspace management.
- Complex analytics dashboards.
- Menu bar fallback for accessibility/recovery in v1 (defer to later release).
- Paid monetization flow in MVP (free MVP first; trial/paywall decision deferred).

## 6. Design Considerations

- The visual style should feel calm, minimal, and emotionally warm.
- Prioritize subtle motion and clear states over decorative effects.
- Avoid dense controls; default to a single primary action with progressive disclosure.
- Ensure notch interactions are legible and usable on different wallpaper/contrast conditions.

## 7. Technical Considerations

- Stack: Swift + SwiftUI, AVFoundation, local persistence via Core Data or equivalent local store.
- Architecture should isolate timer logic, audio engine, and persistence for easier testing.
- Audio engine should avoid glitches when switching tracks during active sessions.
- Ensure timer accuracy under app backgrounding and system sleep/wake transitions.
- Optimize memory and CPU for always-available companion behavior.

## 8. Success Metrics

- Session completion rate >= 60% among active users.
- Median sessions per active day >= 4.
- Day-7 retention >= 40%.
- Technical KPI: launch time < 1 second on target hardware.
- Technical KPI: idle CPU < 3% in release profiling.

## 9. Open Questions

- None for current MVP scope. Resolved product decisions:
- Notch-only v1; menu bar fallback is planned for later.
- Auto-start next interval default is OFF.
- No global shortcut in MVP (KISS).
- Streak counts completed work sessions only.
- MVP remains free until Apple account setup is complete; monetization model will be decided later.
