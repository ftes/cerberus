---
# cerberus-v7ub
title: Treat normal Firefox WS close as non-error
status: completed
type: bug
priority: normal
created_at: 2026-03-01T14:19:04Z
updated_at: 2026-03-01T14:20:44Z
---

Suppress noisy error logs for normal BiDi websocket close (code 1000) by treating it as normal shutdown path in WS handling, while keeping real failures visible.

## Todo
- [x] Audit current WS close handling path and OTP termination reason
- [x] Implement normal-close mapping to :normal shutdown
- [x] Run focused Firefox/browser tests to confirm no failures and no noisy error log
- [x] Run format + precommit checks
- [x] Summarize and complete bean

## Summary of Changes
- Updated WS disconnect handling in `lib/cerberus/driver/browser/ws.ex` so remote close code `1000` maps to a normal GenServer stop reason (`:normal`), which avoids noisy OTP error logs while preserving disconnect notifications.
- Fixed an uncovered init-time disconnect return path to return a valid `GenServer.init/1` stop tuple (`{:stop, reason}`) and still emit disconnect events.
- Added regression coverage in `test/cerberus/driver/browser/ws_test.exs` asserting that a server close frame (`1000`) results in `{:DOWN, ..., :normal}` and preserved owner disconnect event semantics.
- Verified with focused Firefox run (`CERBERUS_BROWSER_NAME=firefox mix test test/cerberus_test.exs:32`) that the `{:remote_close, {1000, ""}}` error log is no longer emitted.
- Ran `mix format` and `mix precommit` successfully.
