---
# cerberus-r4zx
title: PT live radio choose non-form parity
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T20:27:38Z
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

## Progress Notes (2026-03-05 iteration)
- Implemented live radio choose parity for outside-form phx-click controls in lib/cerberus/driver/live.ex.
- Added contract validation so choose on radios outside forms now raises ArgumentError unless the input has phx-click.
- choose now sends radio value payload on live phx-click dispatch, matching fixture event handler expectations.
- Unskipped imported tests in test/cerberus/phoenix_test/live_test.exs:
  - works with a phx-click outside of a form
  - raises an error if radio is neither in a form nor has a phx-click
- Added first-class regression coverage outside imported suites in test/cerberus/select_choose_behavior_test.exs:
  - LiveView choose outside forms dispatches input phx-click payloads (phoenix and browser)
  - LiveView choose outside forms without phx-click raises a contract error (phoenix)
- Fixed a browser parity issue discovered while adding first-class coverage: browser choose now dispatches click for radios with phx-click (lib/cerberus/driver/browser/action_helpers.ex).

## Test Runs
- source .envrc and PORT=4632 mix test test/cerberus/select_choose_behavior_test.exs
  - 37 tests, 0 failures
- source .envrc and PORT=4633 mix test test/cerberus/phoenix_test/live_test.exs:812 test/cerberus/phoenix_test/live_test.exs:863
  - 7 tests, 0 failures
- source .envrc and PORT=4634 mix test test/cerberus/phoenix_test
  - 372 tests, 0 failures, 2 skipped

## Summary of Changes
Fixed PT live radio choose parity for non-form phx-click and missing-form validation contract. Imported PhoenixTest live suite now has only 2 skipped tests remaining, both unrelated to radio choose.
