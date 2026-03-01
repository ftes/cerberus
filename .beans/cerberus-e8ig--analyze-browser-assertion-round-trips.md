---
# cerberus-e8ig
title: Analyze browser assertion round-trips
status: completed
type: task
priority: normal
created_at: 2026-03-01T14:06:12Z
updated_at: 2026-03-01T14:07:55Z
---

Investigate whether browser-driver assertions (, , ) avoid repeated Elixir<->browser round-trips while waiting.

## Todo
- [x] Locate browser assertion code paths
- [x] Trace wait-loop behavior and polling strategy
- [x] Summarize efficiency and round-trip characteristics

## Summary of Changes
- Traced assert_has and refute_has from Cerberus.Assertions through browser driver snapshot/readiness calls.
- Traced assert_path and refute_path through LiveViewTimeout browser retry loop and browser path refresh calls.
- Verified readiness wait behavior runs inside browser via a single script.evaluate promise with DOM observers/events, while assertion retries still perform repeated Elixir to browser calls.
