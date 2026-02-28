---
# cerberus-m6wf
title: Add explicit tests for select and choose unsupported behavior
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-02-28T16:14:02Z
---

Missing-tests follow-up: select/choose are public APIs but explicit unsupported semantics are not directly tested.

## Scope
- Add tests asserting current unsupported behavior and error messaging
- Cover both phoenix and browser sessions where relevant

## Acceptance
- select/choose unsupported behavior is pinned by tests

## Summary of Changes

- Added explicit tests in test/cerberus/public_api_test.exs for select and choose unsupported semantics.
- Covered non-browser sessions (static and live) and browser sessions with assertions on explicit driver-specific unsupported messages.
- Verified via mix test test/cerberus/public_api_test.exs --exclude browser (browser-tagged cases remain for browser-enabled runs).
