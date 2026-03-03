---
# cerberus-fqkw
title: Roll out shared browser sessions across remaining unit suites
status: completed
type: task
priority: normal
created_at: 2026-03-03T10:30:33Z
updated_at: 2026-03-03T10:50:40Z
---

Apply shared browser-session reuse to remaining safe cross-driver unit-style tests to cut browser startup overhead.\n\nScope:\n- [x] Convert remaining safe cross-driver modules to shared browser session setup\n- [x] Keep isolation-sensitive modules unchanged (sandbox/multi-user semantics)\n- [x] Run format + focused impacted suites + precommit\n- [x] Commit code + bean

## Summary of Changes

- Added `Cerberus.TestSupport.SharedBrowserSession` helper to own a single browser session for each converted module via `setup_all` and expose `driver_session/2` mapping.
- Converted 13 additional cross-driver unit-style test modules to reuse one browser session per module instead of starting a new browser session per browser test.
- Left isolation-sensitive suites unchanged (notably sandbox/multi-user ownership-sensitive behavior).
- Ran `mix format`, focused impacted suites, and `mix precommit` successfully before commit.
