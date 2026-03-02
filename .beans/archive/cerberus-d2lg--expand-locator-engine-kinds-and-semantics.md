---
# cerberus-d2lg
title: Expand locator engine kinds and semantics
status: completed
type: feature
priority: normal
created_at: 2026-03-01T16:00:44Z
updated_at: 2026-03-01T21:54:00Z
blocked_by:
    - cerberus-1xnx
---

Implement a fuller locator engine beyond the current slice: first-class role/label/placeholder/alt text/title/testid lookup semantics across Static, Live, and Browser drivers (with browser-oracle parity coverage).

## Prerequisite
- Complete cerberus-1xnx rich locator oracle corpus updates first; preserve and extend that corpus as this bean lands.

## Todo
- [x] Extend locator API/normalization with placeholder/alt/title kinds and richer role mappings
- [x] Implement locator-kind semantics in assertions/actions across static/live/browser drivers
- [x] Expand oracle + core behavior tests for new locator kinds and tricky parity cases
- [x] Run format + targeted tests + precommit
- [x] Summarize and complete bean

## Progress Notes
- Optimized browser assertion helper candidate collection: use querySelectorAll fast path instead of full tree walk when selector/prefilter is available.
- Added match-by prefilter selectors for safe kinds (label/link/button/placeholder/title/testid).
- Reduced per-candidate work by precomputing normalized expected text and avoiding hidden-state checks when not needed.
- Scoped MutationObserver to resolved roots when scope is present (fallback to document root).
- Bumped helper preload version to force updated injected helper in long-lived sessions.


## Summary of Changes
- Completed locator-kind expansion across static, live, and browser drivers, including helper constructors and normalization for role, placeholder, title, alt, testid, and composition filters.
- Added deterministic locator filters for count and position constraints, state constraints, and has descendant constraints with cross-driver semantics.
- Improved browser locator matching performance by prefiltering candidate queries and reducing unnecessary traversal work.
- Expanded parity and behavior coverage through locator corpus tests and live plus browser integration cases.
- Verified with mix format, focused warning-as-error test runs, and mix precommit.
