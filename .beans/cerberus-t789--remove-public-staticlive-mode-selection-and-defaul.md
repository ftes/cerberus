---
# cerberus-t789
title: Remove public static/live mode selection and default session to phoenix
status: completed
type: task
priority: normal
created_at: 2026-02-28T06:52:49Z
updated_at: 2026-02-28T07:00:27Z
---

Implement the API change so public callers default to Phoenix mode and only explicitly choose browser.

## Todo
- [x] Update Cerberus public session constructors and docs/types to remove public :static/:live selection.
- [x] Keep internal test/harness ability to pin static/live drivers without public API exposure.
- [x] Update and expand tests for new public API behavior and failure modes.
- [x] Re-read and update README wording/examples to match new API.
- [x] Run mix format and targeted test coverage for API/docs changes.

## Log
- [x] Ran beans prime
- [x] Checked existing beans for related work

- [x] Refactored `Cerberus.session` public constructors to default non-browser Phoenix mode (`session/0`, `session/1`) with explicit browser via `session(:browser, opts)`.
- [x] Added public rejection errors for explicit `:static` and `:live` driver selection.
- [x] Added `session_for_driver/2` as an internal helper and updated harness to use it for static/live/browser pinning.
- [x] Updated public API tests for new constructor behavior and explicit static/live rejection coverage.
- [x] Re-read and updated README examples/wording to use `session()` by default and removed stale `session(mode)` guidance.
- [x] Updated getting-started and cheatsheet docs to align with the new session API.
- [x] Ran `mix format` and targeted tests (`test/cerberus/public_api_test.exs --exclude browser`, `test/core/auto_mode_test.exs test/core/documentation_examples_test.exs --exclude browser`, `test/core/form_button_ownership_test.exs --exclude browser`).

## Summary of Changes

Implemented removal of public explicit live/static driver selection. Public callers now use `session()` (or `session(:phoenix)`) for non-browser behavior and `session(:browser)` for explicit browser behavior. Internal test/harness driver pinning remains available through `session_for_driver/2`, and docs/tests were updated to match the new public API story.
