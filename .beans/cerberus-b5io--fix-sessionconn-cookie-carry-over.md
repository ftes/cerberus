---
# cerberus-b5io
title: Fix session(conn) cookie carry-over
status: in-progress
type: bug
priority: normal
created_at: 2026-03-05T09:18:24Z
updated_at: 2026-03-05T09:28:26Z
---

## Goal
Fix session/auth carry-over when Cerberus session starts from a seeded Plug.Conn.

## Todo
- [x] Preserve cookie headers during conn recycle in Cerberus.Phoenix.Conn
- [x] Add regression coverage for session(conn) with cookie-backed auth
- [x] Run targeted tests and slow tests
- [ ] Summarize and commit
