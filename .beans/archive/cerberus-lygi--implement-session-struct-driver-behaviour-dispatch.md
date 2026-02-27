---
# cerberus-lygi
title: Implement Session struct + Driver behaviour + dispatcher
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:10Z
updated_at: 2026-02-27T08:06:53Z
parent: cerberus-sfku
---

## Scope
Create core runtime contracts for tri-driver architecture.

## Deliverables
- `Cerberus.Session` struct + constructors for static/live/browser.
- `Cerberus.Driver` behaviour.
- central dispatcher in `Cerberus.Assertions` and action modules.

## Required Fields
- driver kind
- driver state
- current path
- last operation diagnostics

## Done When
- [x] compile-time enforcement exists for driver callbacks.
- [x] API calls route to driver implementation via session.driver.
- [x] unknown driver returns explicit error.

## Summary of Changes
- Added `Cerberus.Session` with driver, driver_state, current_path, and last_result diagnostics.
- Added `Cerberus.Driver` behaviour and implemented the callback contract in static/live/browser adapters.
- Added central dispatch in public API and assertions, including explicit unknown-driver errors.
