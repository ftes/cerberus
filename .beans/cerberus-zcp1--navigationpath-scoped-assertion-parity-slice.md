---
# cerberus-zcp1
title: Navigation/path + scoped assertion parity slice
status: todo
type: task
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T11:00:49Z
parent: cerberus-zqpu
---

## Scope
Close major navigation/assertion ergonomics gap versus PhoenixTest while preserving Cerberus semantics.

## Capability Group
- assert_path / refute_path
- current path/query normalization helpers (for diagnostics and assertions)
- within-style scoped operations and assertions

## Notes
- Maintain existing assert_has/refute_has options and failure formatting.
- Ensure path assertions behave consistently across static/live/browser drivers.

## Done When
- [ ] Path assertion API is documented and implemented for supported drivers.
- [ ] Scoped assertion flow (within) works in at least one end-to-end scenario.
- [ ] Failure messages include normalized path/scope details.
