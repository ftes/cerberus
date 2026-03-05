---
# cerberus-9f29
title: PT live checkbox and uncheck non-form parity
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:56Z
updated_at: 2026-03-05T14:14:56Z
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
