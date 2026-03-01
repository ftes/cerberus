---
# cerberus-8exd
title: Fix Firefox BiDi websocket handshake 400
status: completed
type: bug
priority: normal
created_at: 2026-03-01T09:20:58Z
updated_at: 2026-03-01T09:30:57Z
---

Resolve Firefox browser session init failures where WebSockex handshake to geckodriver BiDi endpoint returns 400 Bad Request in local and CI runs.


## Implementation Checklist

- [x] Reproduce Firefox BiDi 400 locally with a minimal failing test
- [x] Identify handshake-level root cause and validate with direct socket probes
- [x] Implement WS transport fix compatible with Chrome and Firefox
- [x] Add regression tests for handshake behavior and BiDi frame forwarding
- [x] Run local format and targeted browser validations
- [x] Run precommit and targeted local validation before push
- [x] Push commit and verify CI


## Summary of Changes

- Reproduced Firefox startup failure and confirmed geckodriver BiDi endpoint returns HTTP 400 when websocket handshake Host header omits :port.
- Replaced browser WS transport implementation with an in-project GenServer websocket client that sends correct Host headers, handles masked outbound text frames, parses inbound frames, and keeps existing BiDi owner events.
- Added websocket regression tests covering non-default Host:port handshake formatting and incoming text frame forwarding.
- Kept runtime updates for browser service args (`--websocket-port=0` for geckodriver) and Chrome args (`--remote-debugging-port=0`).
- Validated locally (`mix precommit`, targeted runtime/ws tests, cerberus constructor path, explicit browser tests) and in CI run 22540489659 (success).
