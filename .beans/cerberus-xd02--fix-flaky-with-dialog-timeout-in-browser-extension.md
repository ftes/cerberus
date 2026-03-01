---
# cerberus-xd02
title: Fix flaky with_dialog timeout in browser extensions test
status: completed
type: bug
priority: normal
created_at: 2026-03-01T18:01:37Z
updated_at: 2026-03-01T18:14:44Z
---

Intermittent timeout waiting for browsingContext.userPromptOpened in CoreBrowserExtensionsTest. Identify race and make with_dialog robust under event ordering.


## Todo
- [x] Reproduce/inspect timeout race in with_dialog.
- [x] Implement race-safe dialog waiting strategy.
- [x] Run targeted/repeated browser_extensions_test stress runs on Chrome and Firefox to validate behavior.
- [x] Run mix format + targeted tests + mix precommit (precommit failed only due unrelated unformatted file in other in-progress changes).
- [x] Commit code and bean updates.

## Summary of Changes
- Moved dialog BiDi event subscription to browsing-context lifecycle by adding `browsingContext.userPromptOpened` and `browsingContext.userPromptClosed` to context-level session subscriptions.
- Simplified `Browser.with_dialog/3` to use only local `BiDi.subscribe`/`unsubscribe` for event delivery, removing per-call protocol `session.subscribe`/`session.unsubscribe` round-trips.
- This removes the just-in-time subscription race window that could miss `userPromptOpened` and produce intermittent timeout failures.
- Validation: targeted browser extensions test suite passed on Chrome + Firefox; repeated stress runs of the flaky test passed 60/60 on Chrome and 60/60 on Firefox.
- `mix precommit` was run and failed only due an unrelated pre-existing unformatted file (`test/cerberus/core/open_browser_behavior_test.exs`) outside this change.
