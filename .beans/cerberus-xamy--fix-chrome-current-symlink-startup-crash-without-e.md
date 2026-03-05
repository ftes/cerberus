---
# cerberus-xamy
title: Fix chrome-current symlink startup crash without envrc
status: completed
type: bug
priority: normal
created_at: 2026-03-05T18:27:30Z
updated_at: 2026-03-05T18:39:26Z
---

Reproduce and fix mix test --failed startup cascades caused by managed Chrome startup when CHROME env is unset and runtime falls back to tmp/chrome-current symlink. Ensure fallback resolves to real executable path so app bundle frameworks load correctly.

## Summary of Changes
- Resolved managed Chrome fallback startup crashes when CHROME env is unset by resolving symlink targets to real executable paths in Cerberus.Driver.Browser.Runtime.
- Fixed Playwright fixture routing split so static routes remain on non-CSRF pipeline and live routes use CSRF pipeline, removing a large regression set in mix test --failed.
- Fixed session recycle behavior in Cerberus.Phoenix.Conn by excluding request cookie headers from preserved headers, allowing configure_session(drop: true) logout flows to actually clear auth state.
- Verified with mix test --failed, targeted Playwright assertion and static regression tests, full mix test, and mix test --only slow.

## Validation
- source .envrc && PORT=4713 mix test --failed
- source .envrc && PORT=4712 mix test test/cerberus/password_auth_flow_test.exs
- source .envrc && PORT=4721 mix test test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs:214
- source .envrc && PORT=4722 mix test test/cerberus/phoenix_test_playwright/upstream/static_test.exs:197
- source .envrc && PORT=4765 mix test
- source .envrc && PORT=4766 mix test --only slow
