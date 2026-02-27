---
# cerberus-zcp1
title: Navigation/path + scoped assertion parity slice
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T18:02:04Z
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
- [x] Path assertion API is documented and implemented for supported drivers.
- [x] Scoped assertion flow (within) works in at least one end-to-end scenario.
- [x] Failure messages include normalized path/scope details.

## Summary of Changes
- Added public API helpers: current_path/1 normalization, assert_path/3, refute_path/3, and within/3 scoped execution.
- Added Cerberus.Path matching/query normalization utilities and Cerberus.Options path option validation.
- Wired scope propagation across static/live/browser sessions and driver transitions.
- Implemented scope-aware static/live HTML lookup and browser DOM extraction/click/submit/fill operations.
- Added scoped fixture coverage (/scoped route + selector-edge sections) and new cross-driver conformance tests for path + within behavior.
- Updated assertion failure formatting to include normalized current_path and scope details, and documented the new APIs in README/fixtures docs.
