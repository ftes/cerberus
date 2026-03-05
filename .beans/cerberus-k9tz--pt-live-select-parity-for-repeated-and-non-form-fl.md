---
# cerberus-k9tz
title: PT live select parity for repeated and non-form flows
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:56Z
updated_at: 2026-03-05T14:14:56Z
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
