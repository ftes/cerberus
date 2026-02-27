---
# cerberus-3qlu
title: Add show_browser config to run headed Chromium
status: completed
type: feature
priority: normal
created_at: 2026-02-27T14:49:55Z
updated_at: 2026-02-27T14:52:18Z
---

Implement support for `show_browser=true` so browser tests launch Chromium headed (`headless=false`).

## Todo
- [x] Locate browser config plumbing and launch options
- [x] Implement `show_browser` handling with safe default
- [x] Add/adjust tests for config behavior
- [x] Update docs for new option
- [x] Run relevant tests (browser config path) and verify
- [x] Summarize changes and close bean if all todo items are done

## Summary of Changes
- Added `show_browser` handling in browser runtime so `show_browser: true` defaults to headed Chromium (`headless=false`).
- Preserved explicit `headless` precedence when provided.
- Added runtime option tests for default headless, show_browser toggle, and override behavior.
- Updated test config/README to document `SHOW_BROWSER` usage.
- Verified with `MIX_ENV=test mix test test/cerberus/driver/browser/runtime_test.exs`.
