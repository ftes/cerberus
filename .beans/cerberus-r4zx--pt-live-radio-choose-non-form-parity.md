---
# cerberus-r4zx
title: PT live radio choose non-form parity
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T14:14:57Z
parent: cerberus-zh82
---

## Problem
Live radio choose parity is incomplete for non-form phx-click and invalid control validation.

## Broken Behavior
- line 851 in live_test: choose outside form with phx-click does not emit expected value update.
- line 879 in live_test: invalid radio without form or phx-click does not raise expected validation contract.

## Suspected Root Cause
Choose action currently handles form-owned radios well but non-form phx-click dispatch path is missing or inconsistent with select and checkbox logic.

## Proposed Fix
1. Add non-form radio flow in choose path with required phx-click validation.
2. Dispatch value payload using resolved radio input value and preserve label-based targeting semantics.
3. Standardize invalid-radio error wording and exception class with parity contract.

## Implementation Targets
- lib/cerberus/driver/live.ex

## Acceptance
- Unskip lines 851 and 879.
- Add first-class regression coverage under test/cerberus for choose outside form with phx-click.
