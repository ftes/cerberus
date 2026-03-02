---
# cerberus-i5mb
title: Rewrite safe PhoenixTest.visit direct calls
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:17:40Z
updated_at: 2026-03-02T07:18:30Z
parent: cerberus-it5x
---

Allow migration task to rewrite PhoenixTest.visit when first arg is already a session (not conn), and add coverage.

## Progress Update

- Added visit to the safe direct-call rewrite set for module-qualified PhoenixTest calls.
- Migration task now rewrites PhoenixTest.visit(session, ...) to Cerberus.visit(session, ...) when the first arg is not conn.
- Existing conn-bootstrap guard remains in place: visit(conn, ...) stays manual and warns.
- Added migration-task coverage for the non-conn direct visit rewrite path.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Summary of Changes

Closed the direct visit migration gap by auto-rewriting safe session-based PhoenixTest.visit calls while preserving manual handling for conn bootstrap flows.
