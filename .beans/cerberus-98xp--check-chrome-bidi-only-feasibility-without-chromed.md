---
# cerberus-98xp
title: Check Chrome BiDi-only feasibility without ChromeDriver
status: completed
type: task
priority: normal
created_at: 2026-03-01T13:53:40Z
updated_at: 2026-03-01T13:54:23Z
---

Determine whether Chrome can run BiDi-only sessions directly (without ChromeDriver), and capture concrete evidence from official sources and local probes.

## Todo
- [x] Check spec requirement level for BiDi-only support
- [x] Inspect Chrome/ChromeDriver implementation sources
- [x] Run local direct-Chrome BiDi probe
- [x] Run local ChromeDriver BiDi-only WebSocket probe
- [x] Summarize conclusion with evidence links

## Summary of Changes

- Verified spec language: BiDi-only sessions are optional (implementations "should" allow them), not mandatory.
- Confirmed in Chromium source that ChromeDriver exposes unbound WebSocket session bootstrap (), handles  and , and returns  from ChromeDriver host/session path.
- Confirmed in Chromium source that ChromeDriver starts and mediates BiDi mapper + initial  flow for Chrome automation.
- Ran local probe against raw Chrome DevTools WebSocket ():  and  both return method-not-found errors.
- Ran local probe against ChromeDriver WebSocket ():  succeeds,  succeeds, and session lifecycle works over BiDi commands.
- Conclusion: Chrome supports BiDi-only bootstrap via ChromeDriver, but not directly from raw Chrome DevTools endpoint; ChromeDriver cannot be removed today for this workflow.

## Summary of Changes (corrected)

- Verified spec language: BiDi-only sessions are optional (implementations should allow them), not mandatory.
- Confirmed in Chromium source that ChromeDriver exposes unbound WebSocket bootstrap at path /session, handles methods session.status and session.new, and returns capability webSocketUrl from a ChromeDriver session path.
- Confirmed in Chromium source that ChromeDriver starts and mediates the BiDi mapper and initial session.new flow for Chrome automation.
- Ran local probe against raw Chrome DevTools WebSocket endpoint ws://127.0.0.1:9222/devtools/browser/... and observed method-not-found errors for both session.status and session.new.
- Ran local probe against ChromeDriver WebSocket endpoint ws://127.0.0.1:9515/session and observed successful session.status, successful session.new, and successful session.end.
- Conclusion: Chrome supports BiDi-only bootstrap via ChromeDriver, but not directly from the raw Chrome DevTools endpoint; ChromeDriver cannot be removed for this workflow today.
