---
# cerberus-fleo
title: PT live active form pruning after field removal
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T20:33:28Z
parent: cerberus-zh82
---

## Problem
Active form snapshot can become stale after conditional field removal, causing submit parity mismatch.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 1105 is skipped.
- Scenario fills two fields, submits, toggles visibility to remove one field, submits again.
- Expected: remaining field persists and removed field is not submitted.

## Suspected Root Cause
Active form state appears to retain removed field entries and submit path does not prune against current DOM before payload generation.

## Proposed Fix
1. Reconcile active form fields against current rendered DOM right before submit.
2. Drop removed fields from payload while preserving defaults and hidden companions that still exist.
3. Ensure reconciliation runs for both direct submit and click_button submit paths.

## Implementation Targets
- lib/cerberus/driver/live.ex
- active form state helper modules if separate

## Acceptance
- Unskip line 1105 in live_test.
- Add first-class regression test outside import suite for field removal before submit.

## Progress Notes (2026-03-05 iteration)
- Fixed live active-form retention and field pruning path for submit() on live phx-submit forms.
- submit_active_form now marks live phx-submit submissions to preserve active form state across successful submits, aligning with PhoenixTest behavior where unchanged inputs remain available on subsequent form actions.
- submit success handlers in lib/cerberus/driver/live.ex now conditionally clear form data only when preservation is not required.
- This preserves values for unchanged fields while still relying on existing pruning logic to remove fields no longer present in the DOM on later submits.
- Unskipped imported test in test/cerberus/phoenix_test/live_test.exs:
  - handles inputs that get removed through other actions without raising error
- Added first-class regression coverage outside imported suites in test/cerberus/form_actions_test.exs:
  - submit/1 keeps active live form values when conditional fields are removed (phoenix)

## Test Runs
- source .envrc and PORT=4636 mix test test/cerberus/phoenix_test/live_test.exs:1088
  - 1 test, 0 failures
- source .envrc and PORT=4638 mix test test/cerberus/phoenix_test/live_test.exs
  - 155 tests, 0 failures, 1 skipped
- source .envrc and PORT=4640 mix test test/cerberus/form_actions_test.exs
  - 21 tests, 0 failures, 1 skipped
- source .envrc and PORT=4641 mix test test/cerberus/phoenix_test
  - 372 tests, 0 failures, 1 skipped

## Summary of Changes
Resolved the active-form stale-state parity bug after conditional field removal by preserving live active form values across submit() success for phx-submit forms and relying on DOM-based pruning at next submit. Imported PhoenixTest suite now has one skip remaining.
