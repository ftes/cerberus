---
# cerberus-6hq8
title: PT live wrapped textarea label resolution
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:36Z
updated_at: 2026-03-05T19:23:19Z
parent: cerberus-zh82
---

## Problem
Wrapped label plus textarea resolution parity is missing for live fill_in.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 411 is skipped.
- fill_in with label Wrapped notes fails to resolve textarea when label wraps the control instead of using for attribute.

## Suspected Root Cause
Form field lookup likely prioritizes explicit label for attribute mapping and misses implicit label wrapping patterns for textarea nodes.

## Proposed Fix
1. Extend live form field label resolution to support implicit wrapping labels for textarea and input controls.
2. Preserve exact and exact false behavior so wrapping lookup does not overmatch.
3. Ensure resolved element path works with active form tracking and submit.

## Implementation Targets
- lib/cerberus/driver/live.ex
- lib/cerberus/html/html.ex or shared label resolution helpers

## Acceptance
- Unskip test/cerberus/phoenix_test/live_test.exs line 411.
- Add first-class regression test under test/cerberus for wrapped textarea label resolution.

## Summary of Changes
- Updated HTML label-to-field resolution to support wrapped controls even when label for points to a missing id.
- Normalized label matching text so nested control text does not contaminate label comparisons.
- Unskipped and passed live wrapped textarea parity case in PhoenixTest import suite.
- Validation: PORT 4321 mix test test/cerberus/phoenix_test/live_test.exs:410 and PORT 4322 mix test test/cerberus/phoenix_test.
