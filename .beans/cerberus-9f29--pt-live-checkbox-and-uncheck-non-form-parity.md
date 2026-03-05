---
# cerberus-9f29
title: PT live checkbox and uncheck non-form parity
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:56Z
updated_at: 2026-03-05T19:56:37Z
parent: cerberus-zh82
---

## Problem
Live checkbox and uncheck parity is incomplete for outside-form phx-click and label to value resolution.

## Broken Behavior
- line 689 and line 754 in live_test: check or uncheck outside form with phx-click does not match expected behavior.
- line 717 and line 789: invalid checkbox missing form or phx-click validation differs from expected contract.
- line 798 and line 812: checkbox abc and def phx-value and JS value flows fail through label-based targeting.

## Suspected Root Cause
Checkbox resolution for outside-form controls does not consistently map label to input id and phx-click metadata. Uncheck path may diverge from check path logic. Validation branch likely does not enforce same contract across check and uncheck.

## Proposed Fix
1. Unify check and uncheck element resolution for form and non-form controls.
2. For non-form controls, require valid phx-click and dispatch correct value payload, including JS command value branch.
3. Ensure label-based lookup for checkbox abc and def resolves exact target inputs before toggling.
4. Align invalid-element error contract for both check and uncheck.

## Implementation Targets
- lib/cerberus/driver/live.ex
- checkbox helper functions in live driver

## Acceptance
- Unskip lines 689, 717, 754, 789, 798, 812.
- Add first-class regression coverage outside phoenix_test import tree for non-form checkbox phx-click and label value mapping.

## Summary of Changes
- Fixed live checkbox/uncheck parity for outside-form phx-click controls and unified contract validation.
- Implemented nameless field fallback in LiveViewHTML for phx-click checkbox/radio controls so label-only lookups resolve via for/id labels.
- Removed temporary debug instrumentation from LiveViewHTML fallback path.
- Added outside-form checkbox click dispatch in live driver so phx-click events fire consistently on check/uncheck.
- Added first-class regression coverage in test/cerberus/live_checkbox_behavior_test.exs for outside-form toggle flow, nameless label-to-input phx-value behavior, and invalid contract errors.
- Verified with targeted tests and full PT suite:
  - PORT=4350 mix test live_test lines 785,798
  - PORT=4354 and PORT=4358 mix test test/cerberus/phoenix_test (372 tests, 0 failures, 4 skipped)
