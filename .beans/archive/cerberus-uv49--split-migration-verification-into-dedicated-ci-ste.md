---
# cerberus-uv49
title: Split migration verification into dedicated CI step
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:24:26Z
updated_at: 2026-02-28T19:24:38Z
---

Adjust CI workflow so regular non-browser tests and migration verification tests run in separate steps.

## Summary of Changes

- Updated `.github/workflows/ci.yml` to separate migration verification from normal non-browser tests.
- `Run non-browser tests` now runs only `test/core/documentation_examples_test.exs` (excluding browser).
- Added dedicated `Run migration verification tests` step for `test/cerberus/migration_verification_test.exs`.

This keeps migration verification excluded from the normal test step and gives clearer CI failure isolation.
