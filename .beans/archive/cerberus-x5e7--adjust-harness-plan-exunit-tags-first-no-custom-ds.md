---
# cerberus-x5e7
title: 'Adjust harness plan: ExUnit tags first, no custom DSL in v0'
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:55:22Z
updated_at: 2026-02-27T07:56:27Z
parent: cerberus-syh3
---

## Scope
Update planning artifacts to reflect the decision to use regular ExUnit tests with `@tag drivers: [...]` in v0.

## Done When
- [x] Harness epic references ExUnit tags instead of a mandatory custom DSL.
- [x] Harness task `cerberus-e5u0` no longer requires a macro/DSL in slice 1.
- [x] Research doc mentions this implementation choice.

## Summary of Changes
- Updated harness epic `cerberus-syh3` to make ExUnit tags + shared helpers the v0 approach.
- Updated harness task `cerberus-e5u0` to remove mandatory macro/DSL language.
- Added explicit ExUnit-tag implementation note to research doc:
  - `docs/research/browser-liveview-harness-research.md`
