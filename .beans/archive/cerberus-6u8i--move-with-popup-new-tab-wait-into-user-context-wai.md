---
# cerberus-6u8i
title: Move with_popup new-tab wait into user-context waiter
status: completed
type: bug
priority: normal
created_at: 2026-03-03T21:32:50Z
updated_at: 2026-03-03T21:43:44Z
parent: cerberus-dsr0
---

Replace external popup tab polling loop with user-context waiter registration so popup detection is coordinated in owning process.

## Summary of Changes

Moved with_popup new-tab waiting into UserContextProcess via await_popup_tab. Added user context popup waiter registration with timeout and internal polling, plus context_ids tracking for known tab ids. Extensions now wait through user context instead of reading tabs/getTree directly. Added a browser test that opens the popup after waiter registration to cover the timing path.
