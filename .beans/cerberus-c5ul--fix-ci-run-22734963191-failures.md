---
# cerberus-c5ul
title: Fix CI run 22734963191 failures
status: completed
type: bug
priority: normal
created_at: 2026-03-05T20:25:33Z
updated_at: 2026-03-05T20:34:25Z
---

Inspect GitHub Actions run 22734963191 job 65933775538, reproduce failing checks locally, and patch code so CI passes.

## Summary of Changes
- Inspected GitHub run 22734963191 job 65933775538 and confirmed failure source: mix test --warnings-as-errors aborted after a compile warning, not test failures.
- Removed module-attribute warning path in test/cerberus/phoenix_test_playwright/upstream/static_test.exs by replacing conditional @ws_endpoint references with direct Application.compile_env lookups.

## Validation
- source .envrc && PORT=4899 mix test --warnings-as-errors --max-failures 1 test/cerberus/phoenix_test_playwright/upstream/static_test.exs (passes with no warnings)

## Notes
- Running full source .envrc && PORT=4898 mix test --warnings-as-errors --max-failures 1 now fails in current local worktree on a separate functional failure in test/cerberus/form_actions_test.exs:148, unrelated to the CI warning-abort root cause from run 22734963191.
