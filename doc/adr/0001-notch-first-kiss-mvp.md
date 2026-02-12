# 0001. Notch-First KISS MVP for Oak

Date: 2026-02-12

## Status

Accepted

## Context

Oak is intended to be a calm macOS focus companion, not a complex productivity dashboard. The initial product direction required clear boundaries so implementation stays small, fast, and aligned with deep-work behavior.

Key decisions needed:

- Primary UI surface for v1
- Session model complexity
- Input model complexity (shortcuts/customization)
- Monetization timing
- What to defer until later phases

## Decision

For MVP, Oak will use a notch-first, KISS architecture and scope:

- Primary surface is notch companion UI only.
- Focus sessions use fixed presets only: `25/5` and `50/10`.
- Auto-start next interval is available but defaults to `OFF`.
- No global keyboard shortcut in MVP.
- Streak is calculated from completed work sessions only.
- MVP is free while Apple account and pricing setup are pending.

Deferred to later releases:

- Menu bar fallback for accessibility/recovery
- Distraction controls (macOS Focus mode trigger, notification silencing)
- Custom durations
- Cross-device sync
- Team/shared focus rooms
- CLI integration
- Paid trial/subscription/purchase flows

## Consequences

### Positive

- Reduces implementation and QA surface for a faster first release.
- Keeps UX simple and emotionally calm, consistent with product vision.
- Lowers risk of over-engineering before core usage signals are validated.
- Makes future expansion explicit through deferred items.

### Negative

- Accessibility/recovery fallback is limited until menu bar mode is added.
- Users wanting customization (durations, shortcuts) may find MVP restrictive.
- Business validation for pricing is delayed until a later milestone.
