---
# cerberus-o2t9
title: Move match round contract into ExUnit
status: completed
type: task
priority: normal
created_at: 2026-03-14T22:52:28Z
updated_at: 2026-03-14T22:53:59Z
---

Replace the dedicated CI mix run step for the Node/JSDOM round contract with a normal ExUnit test, keep npm install in CI, and verify the targeted test flow passes.


## Summary of Changes
- moved the Node/JSDOM round contract coverage into the existing ExUnit contract test by adding a browser-round parity assertion alongside the existing stable HTML expectation test
- removed the standalone bench/run_match_round_contract.exs script and the dedicated CI step that called it, while keeping npm install in CI so the regular test suite has jsdom available
- updated the browser testing guide to point at the normal ExUnit file instead of the old script and verified the focused contract test passes locally
