---
# cerberus-pgqs
title: Re-run EV2-copy shim sweep after conn carry-over fix
status: completed
type: task
priority: normal
created_at: 2026-03-05T09:22:02Z
updated_at: 2026-03-05T09:23:40Z
---

## Goal
Re-run PhoenixTest shim compatibility sweep in ../ev2-copy after session(conn) cookie carry-over fix.

## Todo
- [x] Prepare ev2-copy test scaffolding (cerberus endpoint + random PORT support)
- [x] Run one-by-one shim sweep for non-Playwright PhoenixTest candidates
- [x] Summarize deltas vs previous sweep
- [x] Restore ev2-copy to clean state

## Summary of Changes

Re-ran the full 8-file non-Playwright shim compatibility sweep in ../ev2-copy after the session(conn) cookie carry-over fix in Cerberus. All candidates were temporarily rewritten to import Cerberus.PhoenixTestShim, run under MIX_ENV=test with randomized PORT, then restored.

Result: failure pattern is unchanged overall. Most failures still redirect to /sessions/new, and one helper-level incompatibility remains where EV2 calls PhoenixTest.Driver.current_path/1 against a Cerberus session.
