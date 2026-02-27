---
# cerberus-4yup
title: 'Documentation: Preserve research findings and decisions (ADR + research notes)'
status: completed
type: feature
priority: normal
created_at: 2026-02-27T07:41:48Z
updated_at: 2026-02-27T07:45:33Z
parent: cerberus-efry
---

## Recommendation
Use beans for actionable planning/status, and keep long-form research in docs files linked from beans.

## Why
Beans are excellent for:
- planning, prioritization, dependencies, and execution tracking
- concise decision summaries and acceptance criteria

Docs are better for:
- deep research notes
- architecture rationale over time
- source links, alternatives considered, and rejected options

## Deliverables
- `docs/research/browser-liveview-harness-research.md`
- `docs/adr/0001-tri-driver-architecture.md`
- `docs/adr/0002-session-first-api-locator-first-arg.md`
- `docs/adr/0003-browser-oracle-conformance.md`

## Cross-Linking Rules
- each epic bean links to relevant ADR(s)
- each ADR links back to owning bean IDs
- each completed bean adds `## Summary of Changes` with doc links

## Done When
- [x] initial research summary is captured in docs.
- [x] at least 3 ADRs exist and are linked in bean bodies.
- [x] conformance harness report format documented with examples.

## Summary of Changes
- Added research notes: `docs/research/browser-liveview-harness-research.md`
- Added ADRs:
  - `docs/adr/0001-tri-driver-architecture.md`
  - `docs/adr/0002-session-first-api-locator-first-arg.md`
  - `docs/adr/0003-browser-oracle-conformance.md`
- Documented concrete API examples and conformance report format.
- Linked each ADR to owning bean IDs and milestone/epic references.
