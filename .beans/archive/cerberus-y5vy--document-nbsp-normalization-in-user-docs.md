---
# cerberus-y5vy
title: Document NBSP normalization in user docs
status: completed
type: task
priority: normal
created_at: 2026-03-05T13:47:31Z
updated_at: 2026-03-05T13:47:49Z
---

Add explicit docs in README and cheatsheet that text matching normalizes whitespace including NBSP by default, and how to opt out with normalize_ws: false.

## Summary of Changes
- Added NBSP/whitespace normalization note under Locators in README.
- Added NBSP/whitespace normalization rules in docs/cheatsheet locator section.
- Documented opt-out path via normalize_ws: false in both places.
