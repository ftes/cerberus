---
# cerberus-94z4
title: PT live async multi-live redirect parity
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T14:14:57Z
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
