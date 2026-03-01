---
# cerberus-wvdq
title: Optimize alt/title locator candidate extraction
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:30:38Z
updated_at: 2026-03-01T20:49:35Z
parent: cerberus-d2lg
---

Further optimize browser assertion helper for alt/title matching: avoid broad subtree scans, add strict candidate preselectors, and cache nested alt resolution per assertion pass without changing semantics across static/live/browser drivers.

## Summary of Changes

- Optimized browser assertion helper candidate extraction for alt matching by adding a strict prefilter selector.
- Added per-pass alt source caching to avoid repeated nested alt lookups while scanning candidates.
- Bumped browser assertion helper preload version so sessions load updated helper code.
- Verified behavior with locator-focused suites: helper locator behavior and locator parity tests, then full precommit.
