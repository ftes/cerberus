---
# cerberus-ih2e
title: Expand locator sigil modifiers (role/css/exact/label semantics)
status: completed
type: task
priority: normal
created_at: 2026-02-27T18:18:56Z
updated_at: 2026-02-27T18:33:56Z
parent: cerberus-zqpu
---

Implement advanced locator sigil support with modifiers for locator kind and match behavior, and document explicit input-by-label semantics.

## Todo
- [x] Audit current locator sigil parsing and normalization paths
- [x] Implement sigil modifiers for role/css selector and exact/inexact matching
- [x] Make label-based input lookup explicit and distinct from generic text lookup
- [x] Add/adjust cross-driver tests for new semantics
- [x] Update docs/notes (beans) for the new API behavior
- [x] Run mix format and targeted tests

## Summary of Changes
- Extended `~l` sigil to support modifiers: `r` (role via `ROLE:NAME`), `c` (CSS selector locator), and `e`/`i` (exact/inexact defaults).
- Added locator-level options (`exact`, `selector`) to normalization and threaded them into operation option validation/merging.
- Added `css("...")` helper and `:css` locator normalization support.
- Added selector-aware lookup support across static/live/browser click/fill/submit flows for consistent CSS-targeted behavior.
- Made label locator semantics explicit: `label(...)` is now form-field lookup only and is rejected for click/assert text operations.
- Added tests for sigil modifier parsing, public API behavior, and static/live/browser conformance coverage.
- Updated README with modifier examples and explicit label-vs-text guidance.
