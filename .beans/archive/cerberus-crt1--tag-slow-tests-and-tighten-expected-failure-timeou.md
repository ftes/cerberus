---
# cerberus-crt1
title: Tag slow tests and tighten expected-failure timeouts
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:06:18Z
updated_at: 2026-03-03T15:24:04Z
---

Apply slow tags and default exclusion for heavy tests, add CI slow step, and set immediate-failure timeouts on intentional negative assertions/actions.

## Summary of Changes
- Added default exclusion for slow tests with ExUnit.configure(exclude: [slow: true]) in test/test_helper.exs.
- Tagged the heaviest tests with @tag :slow in locator parity and migration integration modules.
- Added a dedicated CI slow lane step in .github/workflows/ci.yml using mix test --only slow.
- Reduced intentional negative assertion waits by setting timeout: 0 in assertion filter semantics and API failure-message tests.
- Reused shared browser sessions in documentation examples, live form synchronization, and form button ownership modules via SharedBrowserSession helpers.
- Added short timeout (25ms) for no-dialog expected-failure path in browser extensions tests.
- Validated full suite and slow lane with source .envrc: mix test --slowest 10 (95.6s, 0 failures, 3 excluded) and mix test --only slow (47.2s, 0 failures).
