---
# cerberus-pml5
title: Restore Firefox browser lane and add Chrome vs Firefox speed comparison
status: completed
type: task
priority: normal
created_at: 2026-03-08T20:04:39Z
updated_at: 2026-03-08T20:09:58Z
---

## Scope

- [x] Re-enable Firefox/geckodriver support in Cerberus where it was recently removed or ignored.
- [x] Add an explicit Firefox suite lane so the regular browser-heavy test files can be run under Firefox without ad hoc env setup.
- [x] Run targeted browser verification for both Chrome and Firefox locally if available.

## Notes

- User explicitly asked to add Firefox/geckodriver back for this investigation.
- Motivation: chromium-bidi issue 3974 reports Chrome BiDi script evaluation being much slower than Firefox BiDi and CDP.
- The goal is diagnostic comparison, not CI expansion unless needed by the implementation.
- Prefer comparing the same existing slow browser-heavy file under Chrome and Firefox over adding a synthetic benchmark.

## Summary of Changes

- Made the test bootstrap honor CERBERUS_BROWSER_NAME for Chrome or Firefox runtime wiring.
- Added a mix test.firefox alias that runs the normal suite under Firefox.
- Updated browser docs to document the explicit Firefox suite lane.
- Verified the same browser-heavy files under both lanes locally and recorded the comparison row: browser_extensions_test.exs took 19.9s on Chrome and 20.6s on Firefox.
