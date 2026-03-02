---
# cerberus-zw8h
title: Fill remaining migration task rewrite gaps and add coverage
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:04:24Z
updated_at: 2026-03-02T07:06:38Z
parent: cerberus-it5x
---

Follow-up migration implementation pass: auto-rewrite safe PhoenixTest direct calls and PhoenixTest.Assertions direct calls where possible, reduce unnecessary manual warnings, and add focused migration task tests.

## Progress Update

- Implemented automatic migration rewrites for safe module-qualified direct calls:
  - PhoenixTest.<function>(...) now rewrites to Cerberus.<function>(...) for supported non-browser APIs.
  - PhoenixTest.Assertions.<assertion>(...) now rewrites to Cerberus.<assertion>(...) for assertion/path helpers.
- Kept unsafe patterns manual with warnings (for example visit(conn, ...), browser helper calls, and unknown PhoenixTest direct calls).
- Added migration-task coverage for:
  - safe direct-call rewrites,
  - import PhoenixTest.Assertions rewrite,
  - unsupported direct PhoenixTest function warning path.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Summary of Changes

Filled remaining migration-task rewrite gaps by auto-migrating safe direct PhoenixTest calls and expanded test coverage to lock in rewrite and warning behavior.
