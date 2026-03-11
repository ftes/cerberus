---
# cerberus-j4ho
title: Implement metadata-driven live portal click dispatch
status: completed
type: task
priority: normal
created_at: 2026-03-11T08:08:44Z
updated_at: 2026-03-11T08:15:25Z
---

## Goal

Make live-driver click dispatch work for portal-backed elements by using metadata from Cerberus node resolution instead of relying solely on LiveViewTest.element/3 selector lookup.

## Todo

- [x] Inspect existing live click metadata and dispatch helpers
- [x] Implement metadata-driven click fallback for live buttons/links
- [x] Run targeted portal parity tests
- [x] Summarize behavior and remaining gaps

## Summary of Changes

- Added view-level live click/patch wrappers in `Cerberus.Phoenix.LiveViewClient` so the driver can dispatch events without selector re-resolution when needed.
- Enriched live button matches with raw `phx-click`, `phx-target`, and `phx-value-*` metadata, and taught live clickable lookup to search portal template children as additional roots.
- Added a live-driver fallback that decodes button click metadata and dispatches `push`, `patch`, and `navigate` commands directly when `LiveViewTest.element/3` cannot target the node.
- Updated the portal parity test to assert successful clicks on both the phoenix and browser drivers.
- Verified with `source .envrc && PORT=4132 mix test test/cerberus/live_portal_parity_test.exs` and `source .envrc && PORT=4133 mix test test/cerberus/live_click_bindings_behavior_test.exs`.

## Remaining Gaps

- The new metadata dispatch fallback is implemented for live buttons. Links, forms, and broader portal DOM materialization are still separate follow-up work if needed.
