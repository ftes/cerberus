---
# cerberus-k218
title: Investigate manage crew Cerberus test failures
status: completed
type: bug
priority: normal
created_at: 2026-03-11T20:23:51Z
updated_at: 2026-03-11T20:27:43Z
---

Investigate failures in test/ev2_web/live/manage_crew_live/index_cerberus_test.exs and determine whether they come from the recent EV2 compare-lane changes or a separate Cerberus regression.

- [x] reproduce the failing manage crew Cerberus file locally
- [x] identify the regression source and implement the minimal fix
- [x] run focused EV2 verification with random PORT
- [x] summarize changes and mark bean completed if all work is done

## Summary of Changes

Updated the copied manage crew Cerberus test file to match the current original manage crew expectations, including the new filter sort query semantics and redirect path helper. Replaced PhoenixTest-style string selector assertions with proper Cerberus locators so the copied tests execute through the Cerberus browser assertion API. Verified the file with a focused random-port run in EV2.
