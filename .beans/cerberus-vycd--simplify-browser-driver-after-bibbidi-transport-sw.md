---
# cerberus-vycd
title: Simplify browser driver after Bibbidi transport switch
status: completed
type: task
priority: normal
created_at: 2026-03-09T09:55:46Z
updated_at: 2026-03-09T10:17:07Z
---

## Scope

- [x] Remove dead multi-browser branches from the active browser runtime/config surface where Chrome-only policy makes them unnecessary.
- [x] Simplify browser transport/runtime code and tests now that Bibbidi.Connection is the only active BiDi transport layer.
- [x] Update docs and options to match the simplified browser model.
- [x] Re-run focused browser verification plus full quality gates before committing.

## Summary of Changes

- Removed the dead multi-browser public API and option surface: `session(:browser)` is now the only public browser entrypoint, browser-name/firefox/geckodriver options are gone, and docs/tests were updated to match the Chrome-only policy.
- Collapsed the active browser runtime and installer paths to Chrome-only: the runtime no longer branches per browser lane, Firefox install/task support was removed, and test bootstrap now configures only Chrome + ChromeDriver.
- Simplified the Bibbidi transport integration: `Cerberus.Driver.Browser.BiDi` now owns connection lifecycle and subscriptions, while actual browser commands go straight through `Bibbidi.Connection`, removing the extra GenServer command bottleneck.
- Marked unsupported browser-dialog read assertions explicitly in slow tests instead of pretending they still auto-unblock.
