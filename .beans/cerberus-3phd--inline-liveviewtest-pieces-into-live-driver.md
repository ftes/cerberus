---
# cerberus-3phd
title: Inline LiveViewTest pieces into Live driver
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:07:25Z
updated_at: 2026-03-07T06:20:11Z
---

Investigate whether the Live driver can stop depending on Phoenix.LiveViewTest for event helpers by inlining the relevant pieces and reusing Phoenix LiveView's DOM simulation.

- [x] Inspect current Live driver and Phoenix.LiveViewTest coupling
- [x] Identify which LiveView internals can be reused without reimplementing DOM simulation
- [x] Refactor the Live driver to inline the necessary pieces
- [x] Add or update tests for the simplified behavior (validated with existing targeted Live-driver coverage)
- [x] Run format and targeted tests

## Summary of Changes

- Added `Cerberus.Phoenix.LiveViewClient`, a small local shim that inlines the thin `Phoenix.LiveViewTest` wrapper layer for `element/form/render/render_click/render_change/render_submit`.
- Updated `Cerberus.Driver.Live` to use the local shim for selector-based event dispatch and rendering, while continuing to rely on upstream `ClientProxy`, `__live__`, child lookup, and upload helpers.
- Verified the refactor with targeted Live-driver tests after formatting.

- Removed now-unreachable `live_patch` branches that Dialyzer could prove impossible on these selector-based helper paths.
