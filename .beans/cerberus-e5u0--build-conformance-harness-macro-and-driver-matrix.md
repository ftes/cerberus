---
# cerberus-e5u0
title: Build conformance harness macro and driver matrix runner
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:33Z
updated_at: 2026-02-27T08:06:28Z
parent: cerberus-syh3
---

## Scope
Create an ExUnit-tag-based execution engine to run one scenario across multiple drivers.

## Deliverables
- ExUnit helper module for driver-matrix execution
- driver-tag convention (for example: `@tag drivers: [:static, :live, :browser]`)
- matrix runner producing normalized result records

## Tests
- [x] one scenario executes 3 times for drivers static/live/browser.
- [x] failures preserve driver-specific reason but common shape.
- [x] scenario output sortable by operation and driver.

## Done When
- [x] harness can be invoked via dedicated mix task/test tag.

## Summary of Changes
- Added `Cerberus.Harness` with ExUnit-tag driver selection, matrix execution, normalized result records, and aggregated `run!/3` failures.
- Switched conformance tests to use the shared harness and `@moduletag :conformance`.
- Added harness tests covering cross-driver execution, common failure shape, and deterministic sorting by operation/driver.
