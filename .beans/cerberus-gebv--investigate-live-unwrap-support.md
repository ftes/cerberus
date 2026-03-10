---
# cerberus-gebv
title: Investigate Live unwrap support
status: completed
type: task
priority: normal
created_at: 2026-03-10T17:37:19Z
updated_at: 2026-03-10T17:38:23Z
---

## Goal
Answer whether Cerberus still supports `unwrap/2` for the Live driver, and whether that remains possible if the implementation stops relying on `Phoenix.LiveViewTest` as-is.

## Todo
- [x] Read current Live unwrap implementation and tests
- [x] Read prior unwrap design notes
- [x] Summarize support status and constraints for the user

## Summary of Changes
- Confirmed the Live driver still implements `unwrap/2` directly and passes the active `Phoenix.LiveViewTest.View` into the callback.
- Verified Live unwrap remains covered by integration tests, including redirect-following behavior and the missing-view error case.
- Confirmed the current implementation still depends on `Phoenix.LiveViewTest` primitives, so keeping Live unwrap unchanged requires preserving some equivalent native Live handle.
