---
# cerberus-8exd
title: Fix Firefox BiDi websocket handshake 400
status: in-progress
type: bug
priority: normal
created_at: 2026-03-01T09:20:58Z
updated_at: 2026-03-01T09:27:37Z
---

Resolve Firefox browser session init failures where WebSockex handshake to geckodriver BiDi endpoint returns 400 Bad Request in local and CI runs.


## Implementation Checklist

- [x] Reproduce Firefox BiDi 400 locally with a minimal failing test
- [x] Identify handshake-level root cause and validate with direct socket probes
- [x] Implement WS transport fix compatible with Chrome and Firefox
- [x] Add regression tests for handshake behavior and BiDi frame forwarding
- [x] Run local format and targeted browser validations
- [x] Run precommit and targeted local validation before push
- [ ] Push commit and verify CI
