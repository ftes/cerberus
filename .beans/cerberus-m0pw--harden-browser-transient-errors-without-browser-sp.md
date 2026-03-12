---
# cerberus-m0pw
title: Harden browser transient errors without browser-specific driver branches
status: completed
type: bug
priority: normal
created_at: 2026-03-12T11:34:09Z
updated_at: 2026-03-12T11:42:31Z
---

Make the browser driver recover from transient runtime/evaluation errors in a browser-agnostic way, not via Firefox-specific call-site patches. Remove browser-specific code paths outside startup where practical, especially around transient retries and browser-only feature gating, and verify on both Chrome and Firefox with focused tests and EV2 repros.

## Summary of Changes

- Added a shared transient browser error helper in lib/cerberus/driver/browser/transient_errors.ex and switched the browser driver, browser extensions, and browsing-context process to use shared browser-agnostic retry classification instead of duplicated navigation-only predicates.
- Generalized retry recovery to attempt active-tab recovery for retryable browser transport/evaluation failures, rather than only for a narrow missing-context branch.
- Kept browser-name branching confined to startup/runtime code paths; no non-startup browser driver files still branch on chrome vs firefox.
- Removed the stale Chrome-specific comment from user-context user-agent fallback.
- Added focused tests in test/cerberus/driver/browser/transient_errors_test.exs and retained the deterministic transient assert_path regression coverage.

## Verification

- source .envrc && PORT=4379 mix test test/cerberus/driver/browser/transient_errors_test.exs
- source .envrc && PORT=4380 mix test test/cerberus/browser_timeout_assertions_test.exs test/cerberus/browser_extensions_test.exs
- source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4381 mix test test/cerberus/browser_timeout_assertions_test.exs test/cerberus/browser_extensions_test.exs
- source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4384 mix test --warnings-as-errors
- source .envrc && PORT=4385 mix test --warnings-as-errors
- source /Users/ftes/src/cerberus/.envrc && PATH=/Users/ftes/src/ev2-copy/tmp/test-bin:$PATH PORT=4382 CERBERUS_BROWSER_NAME=firefox mix test test/features/tfa_cerberus_test.exs --max-cases 1

## Follow-up

- The separate EV2 Firefox create-offer toast assertion issue still reproduces and remains tracked in cerberus-ptal.
