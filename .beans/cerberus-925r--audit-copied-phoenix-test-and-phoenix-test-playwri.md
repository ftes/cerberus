---
# cerberus-925r
title: Audit copied phoenix_test and phoenix_test_playwright tests
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:47:02Z
updated_at: 2026-03-06T08:50:15Z
---

Review Cerberus tests copied from phoenix_test and phoenix_test_playwright, classify each as useful unique coverage vs duplicate of existing core tests, and report findings.

## Todo
- [x] Identify copied test modules/cases
- [x] Compare each copied case against existing Cerberus core coverage
- [x] Classify cases into helpful vs duplicate with rationale
- [x] Share concise recommendation summary

## Summary of Changes
Audited copied suites under test/cerberus/phoenix_test and test/cerberus/phoenix_test_playwright plus compat tests. Counted 390 copied-suite tests, with 336 concentrated in static_test/live_test/assertions_test. Mapped copied coverage areas against current Cerberus core suites (browser_extensions, browser_test, open_browser_behavior, form_actions, select_choose_behavior, live_select_regression, live_upload/static_upload, current_path/path_scope/assertion_filter semantics, static_navigation/live_link_navigation, sql_sandbox_behavior). Classified modules into high-value compatibility checks versus mostly duplicate core behavior checks and prepared a keep/prune recommendation.
