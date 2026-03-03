---
# cerberus-l4za
title: Make browser assert_dialog waiter atomic in tab process
status: completed
type: bug
priority: normal
created_at: 2026-03-03T21:32:44Z
updated_at: 2026-03-03T21:43:44Z
parent: cerberus-dsr0
---

Replace external polling for browser assert_dialog with tab-process active-dialog wait registration/reply to avoid missed dialog-open events.

## Summary of Changes

Moved browser assert_dialog waiting into BrowsingContextProcess via await_dialog_open. The process now does immediate active-dialog check, waiter registration, event-driven waiter resolution on userPromptOpened, and timeout replies with observed dialog events. Extensions now use the process call instead of external polling.
