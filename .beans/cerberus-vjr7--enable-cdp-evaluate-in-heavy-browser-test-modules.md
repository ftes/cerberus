---
# cerberus-vjr7
title: Enable CDP evaluate in heavy browser test modules
status: completed
type: task
priority: normal
created_at: 2026-03-10T17:33:11Z
updated_at: 2026-03-10T17:37:36Z
---

## Goal

Opt the heaviest browser test modules into use_cdp_evaluate and measure module-level runtime changes.

## Todo

- [x] Identify high-yield heavy browser modules to update
- [x] Update shared-browser modules to use use_cdp_evaluate: true
- [x] Update browser-only modules where evaluate-heavy paths justify it
- [x] Measure before vs after on representative modules
- [x] Summarize results and complete the bean

## Summary of Changes

Enabled `use_cdp_evaluate: true` in these high-yield modules:

- `test/cerberus/helper_locator_behavior_test.exs`
- `test/cerberus/select_choose_behavior_test.exs`
- `test/cerberus/form_actions_test.exs`
- `test/cerberus/browser_extensions_test.exs`

For the shared-session modules, this uses the new `SharedBrowserSession.start!/1` support for browser opts. For `browser_extensions_test.exs`, the browser session now opts into CDP evaluate directly.

Also fixed browser value decoding in `lib/cerberus/driver/browser/extensions.ex` so CDP evaluate returns plain decoded maps for object results, preserving existing `evaluate_js` semantics.

Measured warm-cache before/after timings with `/usr/bin/time -p mix test ...` against temporary baseline copies of the original module files:

- helper_locator_behavior: `8.06s` -> `6.48s` (`19.6%` faster)
- select_choose_behavior: `5.30s` -> `4.49s` (`15.3%` faster)
- form_actions: `4.51s` -> `3.87s` (`14.2%` faster)
- browser_extensions: `10.92s` -> `8.82s` (`19.2%` faster)

The improved modules all passed in the timed runs with 0 failures.
