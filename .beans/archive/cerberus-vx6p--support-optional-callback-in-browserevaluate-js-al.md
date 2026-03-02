---
# cerberus-vx6p
title: Support optional callback in Browser.evaluate_js - allow asserting on JS result (like PhoenixTestPlaywright)
status: completed
type: task
priority: normal
created_at: 2026-03-01T20:58:57Z
updated_at: 2026-03-01T21:57:09Z
---

Add optional callback support to Browser.evaluate_js so callers can assert on JavaScript evaluation results, aligned with PhoenixTestPlaywright behavior and expectations.


## Todo
- [x] Extend Browser.evaluate_js API to accept optional assertion callback
- [x] Implement callback execution and failure surfacing semantics
- [x] Add focused tests for callback success and failure paths
- [x] Run format, targeted tests, and precommit
- [x] Summarize and complete bean


## Summary of Changes
- Added Browser.evaluate_js/3 with an optional callback that receives the decoded JavaScript result and returns the original browser session for continued piping.
- Preserved Browser.evaluate_js/2 behavior for direct result retrieval.
- Added unsupported-driver coverage for evaluate_js callback usage on live sessions.
- Added focused callback tests for success and assertion failure propagation paths.
- Updated cheatsheet docs with the evaluate_js callback pattern.
