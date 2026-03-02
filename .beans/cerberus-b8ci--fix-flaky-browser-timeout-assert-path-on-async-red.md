---
# cerberus-b8ci
title: Fix flaky browser timeout assert_path on async redirect
status: completed
type: bug
priority: normal
created_at: 2026-03-02T06:28:28Z
updated_at: 2026-03-02T06:37:38Z
---

Investigate intermittent CI failure in BrowserTimeoutAssertionsTest where assert_path reports mismatch despite matching actual/expected path.

- [x] Reproduce failure with repeated runs and CI-like env
- [x] Identify root cause in browser path assertion logic
- [x] Implement minimal fix with regression coverage
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Update bean summary and status

## Summary of Changes

- Root cause: path assertions depended on __cerberusAssert helper; when helper was missing during redirect timing, fallback hard-coded path/query matches to false even if URL already matched.
- Updated browser path assertion expression fallback to compute path/query matching directly from window.location using the same payload semantics (string/regex + exact + query + assert/refute op).
- Added regression test that deletes window.__cerberusAssert and verifies assert_path("/articles") still passes.
- Ran mix format, mix test test/cerberus/browser_timeout_assertions_test.exs, and mix precommit successfully.
