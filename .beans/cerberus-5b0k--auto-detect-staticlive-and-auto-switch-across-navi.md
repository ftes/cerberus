---
# cerberus-5b0k
title: Auto-detect static/live and auto-switch across navigation; browser opt-in sticky
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T08:07:23Z
updated_at: 2026-02-27T12:43:28Z
parent: cerberus-sfku
---

## Scope
Add PhoenixTest-style automatic static/live driver detection and automatic driver switching on `visit/click/redirect` transitions.

## Behavior
- Default mode should be `:auto` (no manual driver selection required for static/live paths).
- Runtime should detect whether the current page target is static or LiveView and route operations to the correct driver.
- On navigation transitions, driver should switch automatically (static -> live, live -> static) while preserving session semantics.
- Browser mode remains explicit opt-in (`session(:browser, ...)` or equivalent) and is sticky: once in browser mode, no automatic fallback to static/live.

## Design Notes
- Keep selector/query semantics identical regardless of automatic switching.
- Emit diagnostics that include previous driver, next driver, and transition reason (`visit`, `click`, `redirect`, `live_redirect`).
- Keep harness compatibility: same scenario should still run against `:auto`, explicit `:live`, explicit `:static`, and explicit `:browser` where applicable.

## Tests
- [ ] `session(:auto)` starts static for static route and switches to live when navigating to live route.
- [ ] `session(:auto)` starts live for live route and switches to static when navigating to static route.
- [ ] redirect and live_redirect transitions update both `current_path` and active driver.
- [ ] explicit browser sessions do not auto-switch back to static/live.
- [ ] failure output includes transition diagnostics in common shape.

## Done When
- [ ] API docs show no-manual-selection happy path for static/live.
- [ ] conformance harness supports `@tag drivers: [:auto, :browser]` style selection.
- [ ] cross-driver behavior remains deterministic for fixture scenarios.

## Notes (2026-02-27)

- Keep one harness runner (`Cerberus.Harness`) and gate scenarios via driver tags, rather than splitting harness implementations.
- Reuse shared fixture markup primitives for baseline assertions so static/live/browser validate the same DOM contract.
- Keep live-only behavior coverage as extension scenarios (subset driver matrix), while baseline scenarios stay cross-driver.

## Reasons for Scrapping

Explicit driver matrices are preferred over automatic static/live switching. We will keep driver choice explicit in tests and split conformance suites into static+browser and live+browser groups instead of introducing :auto mode.

## Reopened (2026-02-27)

Reopened per product direction: non-browser execution should mirror PhoenixTest behavior by auto-detecting static vs live on first visit and re-evaluating mode after each interaction/navigation transition.
