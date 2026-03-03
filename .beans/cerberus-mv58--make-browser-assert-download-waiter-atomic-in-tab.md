---
# cerberus-mv58
title: Make browser assert_download waiter atomic in tab process
status: completed
type: bug
priority: normal
created_at: 2026-03-03T21:32:35Z
updated_at: 2026-03-03T21:43:44Z
parent: cerberus-ql0l
---

Replace external polling for browser assert_download with tab-process wait registration/reply to guarantee no missed download events.

## Summary of Changes

Moved browser assert_download waiting into BrowsingContextProcess via await_download. The process now does immediate history check, waiter registration, event-driven waiter resolution, and timeout replies with observed download events. Extensions now use the process call instead of external polling.
