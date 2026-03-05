---
# cerberus-94z4
title: PT live async multi-live redirect parity
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T20:35:14Z
parent: cerberus-zh82
---

## Problem
Async multi-live navigation chain parity is still missing.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 1414 is skipped.
- Flow async navigates from one live page to a second async live page and expects title assertion to eventually pass.

## Suspected Root Cause
Timeout polling and transition handling likely assumes one navigation hop and misses handoff across chained live mounts with async assigns.

## Proposed Fix
1. Improve live transition wait logic to handle multi-hop live navigation before settling.
2. On timeout assertions, refresh render source from current live process after each hop instead of stale process.
3. Keep deterministic timeout budget accounting across hop transitions.

## Implementation Targets
- lib/cerberus/driver/live.ex
- live timeout assertion polling helper

## Acceptance
- Unskip line 1414 in live_test.
- Add first-class test outside import suite for async live to live chain with delayed assign.

## Progress Notes (2026-03-05 iteration)
- Revalidated the previously skipped imported test in test/cerberus/phoenix_test/live_test.exs:
  - can handle multiple LiveViews (redirect one to another) with async behavior
- The test now passes without further driver/runtime changes; the skip had become stale after earlier timeout/redirect stabilization work.
- Removed the skip tag from the imported test.
- Confirmed first-class non-imported coverage already exists for this behavior in test/cerberus/timeout_behavior_parity_test.exs:
  - timeout handles multi-live async transitions for both phoenix and browser drivers.

## Test Runs
- source .envrc and PORT=4642 mix test test/cerberus/phoenix_test/live_test.exs:1396
  - 1 test, 0 failures
- source .envrc and PORT=4643 mix test test/cerberus/phoenix_test/live_test.exs
  - 155 tests, 0 failures
- source .envrc and PORT=4644 mix test test/cerberus/phoenix_test
  - 372 tests, 0 failures
- source .envrc and PORT=4645 mix test test/cerberus/timeout_behavior_parity_test.exs
  - 6 tests, 0 failures

## Summary of Changes
Removed the final PT async multi-live redirect skip after verification. No additional runtime code change was required in this iteration because existing timeout/redirect handling now satisfies the scenario.
