---
# cerberus-xd02
title: Fix flaky with_dialog timeout in browser extensions test
status: completed
type: bug
priority: normal
created_at: 2026-03-01T18:01:37Z
updated_at: 2026-03-01T20:06:26Z
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


## Follow-up
- User still reports intermittent with_dialog timeout waiting for browsingContext.userPromptOpened from test/cerberus/cerberus_test/browser_extensions_test.exs:30.
- Reproduce against current tree and harden with_dialog further.


## Follow-up Todo
- [x] Reproduce timeout with current tree and exact failing target.
- [x] Harden with_dialog for missed-event and callback-race cases.
- [x] Validate with repeated runs on both Chrome and Firefox.
- [x] Commit follow-up code + bean update.


## Follow-up 2 Summary
- Added defensive per-call protocol subscription (`session.subscribe`) for dialog events inside `with_dialog/3`, while keeping context-level event subscriptions in place.
- Added stale dialog-event mailbox flushing before action trigger to avoid matching old events.
- Reworked `userPromptOpened` waiting to poll callback task state between event waits and raise a precise error when callback returns without opening a dialog.
- Added regression test for the callback-completed-without-dialog branch.
- Validation on exact failing target (`test/cerberus/cerberus_test/browser_extensions_test.exs:30`): Chrome classifier 80 runs had `timeout=0`; Firefox classifier 80 runs had `timeout=0` and `other=0`.
