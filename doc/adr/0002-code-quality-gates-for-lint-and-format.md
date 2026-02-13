# 0002. Code Quality Gates for Lint and Format

Date: 2026-02-13

## Status

Accepted

## Context

Recent work introduced stricter static checks and formatting rules, plus follow-up refactors:

- `e1ef4bf` - Add SwiftLint and SwiftFormat configuration.
- `78a27d7` - Regenerate project with XcodeGen to include new view files.
- `ae6fc04` - Apply code quality tooling changes and extract `SettingsMenuView`.

As these changes landed, the team needed a stable policy for:

- Which tool is source-of-truth for lint vs format.
- How to handle rule conflicts between SwiftLint and SwiftFormat.
- Which checks are required before considering a change complete.

## Decision

Oak adopts the following code-quality gate policy:

- SwiftLint remains the source-of-truth for lint policy and enforcement (`--strict`).
- SwiftFormat remains the source-of-truth for mechanical formatting.
- Explicit top-level ACL is required by SwiftLint (`explicit_top_level_acl`) and must be preserved.
- SwiftFormat is configured to avoid removing ACL required by lint:
  - disable `redundantInternal`
  - disable `redundantPublic`
- Any new source file extracted during refactoring must be reflected in XcodeGen output (`project.yml` -> regenerate project).
- Required verification sequence for Swift/SwiftUI changes:
  - `just format`
  - `swiftlint lint --strict --no-cache` (or equivalent strict lint run)
  - `just test`

## Consequences

### Positive

- Lint and formatting no longer fight each other on access-control modifiers.
- Code review gets a consistent pre-merge quality baseline.
- Refactors that split files are less likely to break builds due to missing project entries.

### Negative

- More up-front configuration maintenance when new lint/format rules are introduced.
- Contributors must run a stricter verification sequence before merging.
