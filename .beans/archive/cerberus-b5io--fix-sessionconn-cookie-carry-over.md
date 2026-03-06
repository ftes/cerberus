---
# cerberus-b5io
title: Fix session(conn) cookie carry-over
status: completed
type: bug
priority: normal
created_at: 2026-03-05T09:18:24Z
updated_at: 2026-03-06T20:16:46Z
---

## Goal
Fix session/auth carry-over when Cerberus session starts from a seeded Plug.Conn.

## Todo
- [x] Preserve cookie headers during conn recycle in Cerberus.Phoenix.Conn
- [x] Add regression coverage for session(conn) with cookie-backed auth
- [x] Run targeted tests and slow tests
- [x] Summarize and commit

## Summary of Changes
- Preserved cookie headers when starting a session from a seeded Plug.Conn.
- Added cookie-backed auth regression coverage for session(conn) and verified targeted plus slow suites.
