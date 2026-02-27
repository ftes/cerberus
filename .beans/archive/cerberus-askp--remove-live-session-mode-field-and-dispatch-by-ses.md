---
# cerberus-askp
title: Remove Live session mode field and dispatch by session struct
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:03:15Z
updated_at: 2026-02-27T19:09:16Z
---

## Scope
Remove `%Cerberus.Driver.Live{mode: ...}` and derive live/static behavior from session struct + view presence.

## Done When
- [x] Live session struct no longer stores `mode`.
- [x] Live driver behavior remains unchanged for static/live transitions.
- [x] Tests covering auto/live navigation and click semantics pass.

## Summary of Changes

- Removed `mode` from `%Cerberus.Driver.Live{}` and updated `@type t`/`defstruct` accordingly.
- Replaced `session.mode` branching with derived route state helpers in the live driver:
  - `live_route?/1` (live if view is present)
  - `route_kind/1` (`:live` or `:static` derived from session view)
- Updated all internal transition and observed-mode reporting to use derived route state.
- Updated static driver handoff code to construct `%LiveSession{}` without the removed `mode` field.

## Validation

- `mix test test/core/auto_mode_test.exs test/core/live_navigation_test.exs test/core/live_link_navigation_test.exs test/core/live_click_bindings_conformance_test.exs` (pass)
- `mix precommit` (credo pass; dialyzer reports existing baseline warnings outside this slice)
