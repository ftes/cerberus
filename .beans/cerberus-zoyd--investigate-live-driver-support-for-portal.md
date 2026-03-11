---
# cerberus-zoyd
title: Investigate live driver support for portal
status: completed
type: task
priority: normal
created_at: 2026-03-11T07:28:28Z
updated_at: 2026-03-11T07:34:29Z
---

## Goal

Add a parity test covering Phoenix.Component.portal/1 with the live and browser drivers, document the current live-driver gap, and propose a Cerberus API for portal support.

## Todo

- [x] Inspect existing live/browser driver and parity test patterns
- [x] Add a portal parity test and supporting fixture coverage
- [x] Run targeted tests to confirm current behavior
- [x] Summarize findings and propose a portal API

## Summary of Changes

- Added a minimal `/live/portal` fixture that renders a button and counter through `Phoenix.Component.portal/1`.
- Added a cross-driver test that documents current parity: the browser driver can click the teleported button and update the count, while the live driver can assert the initial text but currently raises `no button matched locator` on click.
- Confirmed the failure with `source .envrc && PORT=4128 mix test test/cerberus/live_portal_parity_test.exs`.
- Recommended an internal portal materialization/event-dispatch fix over adding public API if the goal is transparent parity.
