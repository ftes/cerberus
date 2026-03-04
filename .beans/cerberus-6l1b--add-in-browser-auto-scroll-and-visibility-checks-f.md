---
# cerberus-6l1b
title: Add in-browser auto-scroll and visibility checks for actions
status: completed
type: feature
priority: normal
created_at: 2026-03-04T06:34:39Z
updated_at: 2026-03-04T06:45:10Z
---

Implement Playwright-style pre-action scrollIntoView and basic visibility/actionability checks inside JS action helper (single roundtrip).

## Summary of Changes
- Added in-browser `scrollIntoView` before action execution inside `window.__cerberusAction.performResolved`.
- Added basic visibility check (hidden/display:none/visibility hidden|collapse/zero-sized bbox) before action execution.
- Kept implementation in the existing browser-side action helper path; no extra Elixir<->browser roundtrip was added.
- Added failure reasons and mapping for clearer diagnostics:
  - `target_detached`
  - `target_not_visible`
- Added regression coverage in browser extensions fixture/tests:
  - hidden target click now fails with visibility error
  - offscreen click triggers real scroll (`window.scrollY > 0`) before action

## Validation
- `mix test test/cerberus/browser_extensions_test.exs test/cerberus/browser_action_settle_behavior_test.exs` passed.
- Full suite `mix test` passed: 477 tests, 0 failures (3 excluded).
- `mix precommit` currently reports unrelated existing Credo warnings in `test/cerberus_test.exs` (Enum.count warning), outside this change set.
