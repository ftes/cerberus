---
# cerberus-qate
title: Compare timeout behavior across Cuprite/Capybara, Playwright, PhoenixTest
status: completed
type: task
priority: normal
created_at: 2026-03-04T21:41:11Z
updated_at: 2026-03-04T21:41:15Z
---

Investigate how each framework enforces waits/timeouts for assertions/actions and whether framework-level timeouts can be preempted by long single operations.

## Summary of Changes
Compared timeout and waiting semantics across PhoenixTest/PhoenixTest.Playwright, Capybara/Cuprite, and Playwright docs/source. Identified that PhoenixTest live assertion timeout wrapper is retry-loop based (non-preemptive for one long assertion attempt), while Playwright and Capybara/Cuprite generally enforce per-operation wait/timeout windows. Collected source references for each.
