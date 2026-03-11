---
# cerberus-k9o5
title: Add simple browser test concurrency limiter
status: completed
type: task
priority: normal
created_at: 2026-03-11T19:48:20Z
updated_at: 2026-03-11T20:03:23Z
---

Introduce a simple token-based limiter for concurrent browser-based tests in Cerberus and wire it into the EV2 copy consumer.

- [x] inspect current browser test support and EV2 integration points
- [x] implement a simple token-limiter API on Cerberus.Browser with docs and types
- [x] wire EV2 copy tests to acquire/release limiter tokens in setup_all
- [x] run focused formatting and tests for Cerberus and EV2 copy
- [x] summarize changes and mark bean completed if all work is done

## Summary of Changes

Added a simple named browser test token limiter behind Cerberus.Browser.checkout_test_token/1 and checkin_test_token/1, documented the setup_all pattern, covered the limiter with focused tests, and wired EV2 copy browser case setup_all to use a shared limiter with a configurable test limit.


Updated API shape: Cerberus.Browser now exposes limit_concurrent_tests/1, registers on_exit cleanup internally, and defaults the limit from config :cerberus, :browser, max_concurrent_tests.


Updated API again: limit_concurrent_tests/0 now uses the default limiter name so the common setup_all case needs no options.
