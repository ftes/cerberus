---
# cerberus-u6tm
title: Promote core integration tests by removing conformance filename prefix
status: completed
type: task
priority: normal
created_at: 2026-02-27T08:25:37Z
updated_at: 2026-02-27T08:26:22Z
parent: cerberus-syh3
---

## Scope
Make core integration tests visually prominent by removing `conformance_` filename prefixes and placing them in a dedicated top-level core test directory.

## Changes
- move focused integration test files into `test/core/`
- rename files to drop `conformance_` prefix
- update module names to reflect core integration focus

## Done When
- [x] no core integration file starts with `conformance_`.
- [x] core integration tests live under `test/core/`.
- [x] module names align with the new core positioning.

## Summary of Changes
- Moved integration-focused test files out of `test/cerberus/` into a prominent `test/core/` directory.
- Renamed files to `cross_driver_text_test.exs`, `static_navigation_test.exs`, `live_navigation_test.exs`, and `oracle_mismatch_test.exs`.
- Renamed modules from `Cerberus.Conformance*` to `Cerberus.Core*` while keeping `@moduletag :conformance` and driver tags intact.
- Added a short README note pointing to `test/core/` as the location for core integration specs.
