# 0003. Codebase Documentation — Domain Glossary and Codebase Map

Date: 2026-05-25

## Status

Accepted

## Context

As the Oak codebase grew, two documentation gaps became apparent:

1. **No shared domain vocabulary.** The codebase uses domain terms like "Session State", "Preset", "Round", "Display Target", and "Notch Window" across models, views, view models, and services. Without a formal glossary, contributors and AI agents risk using inconsistent terminology — e.g., mixing up "Session Type" with "Preset", or conflating "Round" (a completed work session) with "Session" (any timed interval). This ambiguity compounds when reading architecture docs, writing tests, or onboarding new developers.

2. **Stale codebase map documents.** Seven `planning/codebase/*.md` documents (STACK.md, ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, INTEGRATIONS.md, CONCERNS.md) existed from a previous mapping pass but were out of date. They predated several features: long breaks, configurable durations, session timeline, dynamic island phase 1, auto-start next interval, and the preset settings store. A stale map is worse than no map — it actively misleads readers about the current architecture.

Previous attempts to keep documentation current were ad-hoc. ADR-0002 established code quality gates for lint and format, but no equivalent policy existed for strategic documentation (glossary, architecture overview, domain model).

## Decision

Oak adopts the following documentation practices:

- **CONTEXT.md** at the project root serves as the single source of truth for domain terminology. It defines every domain term used across the codebase in implementation-free language — no framework class names, no file paths, no code snippets. Terms are organized by concept area: Session lifecycle, Session types, Presets, Rounds, Progress, Audio, Display, Window state.

- **`.planning/codebase/`** documents are refreshed on demand via the `codemap` skill (parallel exploration agents covering stack, architecture, structure, conventions, testing, integrations, and concerns). These documents are separately versioned from CONTEXT.md because they capture implementation details and evolve at a different cadence.

- Documentation quality is reviewed as part of PR review, using the same gate philosophy as ADR-0002. Any PR that introduces a new domain term must update CONTEXT.md. Any PR that significantly changes the architecture (new service, new view layer, new persistence strategy) should trigger a codemap refresh.

- The decision to keep CONTEXT.md implementation-free is deliberate: implementation details change frequently but domain concepts are stable. This separation prevents the glossary from going stale.

Alternatives considered and rejected:

- **Inline domain definitions in source comments** — rejected because terms are not searchable or referenceable across files without a central glossary.
- **Combined glossary-and-architecture document** — rejected because the glossary (stable concepts) and architecture docs (evolving implementation) have different change cadences; combining them would create friction for both types of update.
- **Skipping formal documentation entirely** — rejected because onboarding cost and term ambiguity were already causing friction.

## Consequences

### Positive

- **Consistent terminology.** Developers and AI agents can reference CONTEXT.md for precise definitions of every domain term, reducing ambiguity in code, tests, and discussions.
- **Accurate architecture reference.** The codebase map documents now reflect the current state of the codebase, including all recent features.
- **Clear separation of concerns.** The domain glossary (stable, concept-focused) is distinct from the codebase map (evolving, implementation-focused), so each can be updated independently.
- **Reviewable documentation.** PRs that change the domain model are reviewed for glossary accuracy, preventing documentation from drifting silently.

### Negative

- **Maintenance overhead.** CONTEXT.md must be kept in sync with the codebase — a new domain term requires a glossary update. This is mitigated by making it a PR review checklist item rather than a separate process.
- **Refresh effort.** Running the codemap skill is computationally intensive (parallel exploration agents). It should be done deliberately rather than on every PR.
- **No automated enforcement.** Unlike lint rules (ADR-0002), there is no automated check that CONTEXT.md is up to date. Glossary drift may go unnoticed until a reviewer catches it, increasing the burden on code review.
