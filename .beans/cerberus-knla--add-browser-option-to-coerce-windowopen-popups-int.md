---
# cerberus-knla
title: Add browser option to coerce window.open popups into same tab via preload script
status: completed
type: feature
priority: normal
created_at: 2026-03-01T16:41:29Z
updated_at: 2026-03-01T17:17:23Z
---

Implement an early-init popup interception mode so autonomous window.open calls do not create unmanaged popup windows.

## Scope
- Add a browser/session option to enable same-tab popup coercion.
- Inject internal preload script before page JS runs to override window.open behavior.
- Add browser integration tests for autonomous popup-open-on-load flow.
- Update README and public moduledoc option lists.

## Todo
- [x] Add config parsing and internal preload script wiring.
- [x] Add browser fixture route/page that opens popup on load.
- [x] Add browser test coverage for enabled behavior.
- [x] Update docs for new option and workaround limitations.
- [x] Run mix format and targeted tests.
- [x] Run mix precommit (fails on pre-existing Credo refactor findings in browser.ex unrelated to this bean).
- [x] Commit code plus bean file.

## Summary of Changes
- Added browser context popup_mode option with allow default and same_tab override.
- Added an internal preload helper module to override window.open early when popup_mode is same_tab.
- Hardened visit to recover when initial navigation is canceled by a follow-up navigation during page load.
- Added fixture routes/pages and browser integration coverage for autonomous popup-on-load behavior.
- Updated browser config tests and public docs for the new option.
- Ran mix format, targeted tests in a clean worktree, and mix precommit (blocked by pre-existing Credo findings).
