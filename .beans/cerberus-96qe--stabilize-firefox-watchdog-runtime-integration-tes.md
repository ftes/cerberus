---
# cerberus-96qe
title: Stabilize firefox watchdog runtime integration test
status: in-progress
type: bug
priority: normal
created_at: 2026-03-14T16:58:04Z
updated_at: 2026-03-14T17:12:51Z
---

The runtime integration test for direct Firefox watchdog cleanup is flaky in CI because it races a spawned GenServer.stop/3 against System.halt/1. Make the interrupted-runtime case deterministic, rerun focused tests, and confirm the Chrome CI lane does not need a skip.


## Notes
- replaced the helper-based lane exclusion with a direct `@moduletag skip: System.get_env("CERBERUS_BROWSER_NAME") != "firefox"` on the Firefox-only runtime integration module
- verified the module now reports 2 skipped tests in the default lane and still runs/passes in the Firefox lane
- kept the explicit browser user-agent assertion runtime-aware so it remains valid in either configured lane
