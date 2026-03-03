---
# cerberus-nx1s
title: Migrate browser click/submit to in-browser action resolver
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:36:58Z
updated_at: 2026-03-03T08:57:03Z
parent: cerberus-npb0
---

Implement browser-side action helper loop for click and submit with locator resolution, matching, filtering, timeout/retry, and actionability checks inside browser JS.

## Summary of Changes

- Added browser action-helper wiring for click/submit resolution via `Expressions.action_resolve/1`.
- Added resolver preload support (`ActionHelpers`) to browser context defaults and Firefox fallback preload path.
- Routed browser `click` and `submit` through in-browser resolver by default.
- Preserved `:has` behavior by falling back to legacy snapshot+Elixir matching path when composition filters are present.
