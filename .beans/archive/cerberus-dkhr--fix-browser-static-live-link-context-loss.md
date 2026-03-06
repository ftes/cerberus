---
# cerberus-dkhr
title: Fix browser static->live link context loss
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:53:52Z
updated_at: 2026-03-05T15:39:05Z
---

Investigate and fix BiDi context loss when clicking static links into LiveView in browser lane. Repro: test/cerberus/phoenix_test_playwright/upstream/static_test.exs "handles navigation to a LiveView". Current workaround is skipped test.

## Summary of Changes
Switched the /phoenix_test/playwright router scope back to the CSRF browser pipeline (:phoenix_test_playwright_browser_csrf).

This restores stable browser visits to Playwright LiveView fixture routes (for example /phoenix_test/playwright/live/index) and resolves the BiDi context-loss cascade (Cannot find context with specified id leading to startup timeouts) seen in upstream assertions.

Validation:
- PORT=4817 mix test test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs:554
- PORT=4826 mix test test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs
- PORT=4834 mix test test/mix/tasks/cerberus.migrate_phoenix_test_test.exs:554
- PORT=4842 mix test --failed

Note: mix precommit still reports existing Credo issues in unrelated files that were not part of this fix.
