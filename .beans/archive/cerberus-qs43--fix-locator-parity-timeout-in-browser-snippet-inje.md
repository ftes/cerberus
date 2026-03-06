---
# cerberus-qs43
title: Fix locator parity timeout in browser snippet injection
status: completed
type: bug
priority: normal
created_at: 2026-03-04T21:57:37Z
updated_at: 2026-03-04T22:02:09Z
---

Investigate and fix ExUnit timeout in Cerberus.LocatorParityTest caused by browser evaluate path while injecting snippets.

## Summary of Changes
Fixed locator parity timeout flake in browser snippet injection by removing blocking dialog waiter calls from evaluate polling.
- Updated Cerberus.Driver.Browser.Evaluate.maybe_unblock_dialog to probe active_dialog directly per poll instead of calling await_dialog_open with padded call timeouts.
- This keeps the evaluate poll loop bounded by the intended poll interval and command timeout, avoiding occasional multi-second stalls that could push LocatorParityTest past ExUnit timeout.
- Verified with BrowserExtensionsTest plus multiple seeded LocatorParityTest stress runs.
