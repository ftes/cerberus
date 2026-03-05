---
# cerberus-k9tz
title: PT live select parity for repeated and non-form flows
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:56Z
updated_at: 2026-03-05T19:36:18Z
parent: cerberus-zh82
---

## Problem
Live select parity is incomplete for repeated multi-select, outside-form phx-click flows, and invalid select validation contract.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 571: repeated calls on same multi-select do not preserve expected cumulative selection behavior.
- line 581 and line 591: select on controls outside forms with phx-click does not dispatch expected change payload.
- line 629: invalid select missing form or phx-click path does not raise expected contract error.

## Suspected Root Cause
Live select path likely assumes form-bound controls and does not implement outside-form phx-click option dispatch semantics. Multi-select repeated call path may overwrite instead of merge effective selections.

## Proposed Fix
1. In select action, branch by ownership:
   - form-owned select uses active form payload update.
   - non-form select requires valid phx-click and dispatches event payload from selected option values.
2. For multi-select repeated calls, merge selections with current DOM selected state before submit or click dispatch.
3. Normalize invalid select errors to clear actionable message matching parity expectations.

## Implementation Targets
- lib/cerberus/driver/live.ex
- shared form payload builder used by select

## Acceptance
- Unskip lines 571, 581, 591, 629 in live_test.
- Add non-throwaway regression tests under test/cerberus for multi-select repeated calls and outside-form select with phx-click.

## Summary of Changes
- Unskipped and fixed all four select parity cases in PT live suite:
  - repeated multi-select calls
  - outside-form select with option phx-click
  - outside-form multi-select with option phx-click
  - invalid outside-form select contract error
- Implemented cumulative multi-select value preservation across repeated select calls in live form data updates.
- Added option-level phx-click metadata discovery for select fields and wired live select to dispatch option click events when select is outside a form.
- Enforced clear contract error for outside-form select without option phx-click: expected select option to have a valid phx-click attribute on options or to belong to a form.
- Added first-class non-throwaway regression coverage in test/cerberus/live_select_regression_test.exs.
- Validation:
  - PORT 4347 targeted parity tests for static and live data-method plus select parity slices
  - PORT 4348 mix test test/cerberus/phoenix_test
  - PORT 4351 mix test test/cerberus/live_select_regression_test.exs
  - PORT 4354 mix test test/cerberus/phoenix_test test/cerberus/live_select_regression_test.exs
- Follow-up recorded: browser parity gap for these select flows tracked in cerberus-efct.
