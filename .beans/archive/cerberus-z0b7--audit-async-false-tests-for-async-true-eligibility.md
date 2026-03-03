---
# cerberus-z0b7
title: Audit async false tests for async true eligibility
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:37:11Z
updated_at: 2026-03-03T14:48:19Z
---

Review all test modules using async: false, determine if each can run async: true, switch safe cases, and verify with test runs.

- [x] Inventory all async: false occurrences in tests
- [x] Classify each occurrence with reason sync is required or not
- [x] Switch safe modules to async: true
- [x] Run formatting and targeted/full verification tests
- [x] Document results and summary

## Summary of Changes
Reduced sync-only modules from 9 to 3 by moving safe test modules to async and removing global env mutation where feasible.

- Switched to async true: locator parity, explicit browser, SQL sandbox behavior, profiling, install tasks.
- Removed global env writes from profiling and install-task tests by adding process-local overrides in Cerberus.Profiling and Cerberus.Browser.Install.
- Refactored remote webdriver behavior test to pass runtime/base URL via session opts instead of Application.put_env.
- Verified with targeted runs including browser-heavy suites; final validation: 32 tests, 0 failures across touched modules.

Remaining async false modules:
- timeout_defaults_test (intentionally exercises application env fallback behavior)
- driver/browser/config_test (intentionally asserts application browser config precedence)
- remote_webdriver_behavior_test (resets shared browser runtime + container lifecycle in setup_all)
