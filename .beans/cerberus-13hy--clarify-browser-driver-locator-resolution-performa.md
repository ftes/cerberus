---
# cerberus-13hy
title: Clarify browser-driver locator resolution performance semantics
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:28:30Z
updated_at: 2026-03-03T08:28:55Z
---

Answer whether browser driver currently resolves by collecting candidates + Elixir matching, and whether waiting/retries happen in-browser or via roundtrips compared to Playwright locator auto-wait model.

## Summary of Changes
Verified browser driver behavior with line references. Confirmed action ops (click/fill_in/select/choose/check/uncheck/upload/submit) fetch candidate snapshots from browser and perform matching/filtering in Elixir. Confirmed text assertions run mostly in-browser via injected helper with MutationObserver/RAF/poll loop and single evaluate call per assertion. Confirmed path assertions still loop through Elixir recursion with readiness waits and repeated evaluate calls.
