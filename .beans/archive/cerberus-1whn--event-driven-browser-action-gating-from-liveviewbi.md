---
# cerberus-1whn
title: Event-driven browser action gating from LiveView/BiDi signals
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:13:25Z
updated_at: 2026-02-27T12:01:14Z
parent: cerberus-sfku
---

## Scope
Add event-driven synchronization for browser-driver operations so follow-up actions/assertions wait on relevant runtime events instead of relying on fixed polling.

## Motivation
After click/fill/submit/navigation, the next operation should wait for LiveView/BiDi signals (for example diff/update and disconnect/down transitions) that indicate the page is settled for the next assertion/action.

## Initial Direction
- Subscribe to and classify relevant BiDi + LiveView-side events.
- Maintain per-browsingContext readiness state.
- Gate next operation (`assert_has`, `refute_has`, `click`, `fill_in`, `submit`) on readiness with bounded timeout.
- Keep deterministic behavior and clear timeout diagnostics.

## Done When
- [x] Browser driver uses event-driven readiness before follow-up operations.
- [x] Integration tests cover at least one live update sequence and one disconnect/reconnect/down edge case.
- [x] Timeout/failure messages include the awaited signal and last observed state.

## Summary of Changes
- Added BiDi subscriber support in `Cerberus.Driver.Browser.BiDi` and broadcast of non-command BiDi events to subscribers.
- Extended `BrowsingContextProcess` with `await_ready/2` and `last_readiness/1`, plus per-browsingContext tracking of recent BiDi navigation/load events.
- Implemented event-driven readiness probe (LiveView page-loading events, DOM mutations, connected/disconnected/down state) in browsingContext process and removed browser driver snapshot polling loops.
- Gated browser operations (`click`, `fill_in`, `submit`, `assert_has`, `refute_has`) on readiness and improved timeout diagnostics to include awaited signal set and last observed state.
- Added handling for `script.evaluate` navigation race (`Inspected target navigated or closed`) as a valid navigation transition signal.
- Verified with browser-backed integration tests covering live updates and live-to-static teardown navigation (`test/core/live_navigation_test.exs`) and browser form-action flow (`test/core/form_actions_test.exs`).
