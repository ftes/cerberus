---
# cerberus-iwe2
title: Fix Firefox CI failures and make CI sequential
status: completed
type: bug
priority: normal
created_at: 2026-03-12T08:21:43Z
updated_at: 2026-03-12T08:25:17Z
---

Fix the Firefox CI failures from the new lane and change the workflow so Firefox runs as an extra sequential step in the main CI job.

- [x] inspect failing Firefox tests and identify browser-specific assumptions
- [x] fix tests or implementation for Firefox parity
- [x] change CI workflow to run Firefox sequentially in the main CI job
- [x] verify full local Firefox suite again
- [x] summarize results and follow-ups

## Summary of Changes

- changed .github/workflows/ci.yml to keep Firefox as an extra sequential step in the main CI job instead of a separate job
- expanded the shared browser runtime cache to include Firefox and keyed it by both Chrome and Firefox versions
- verified the sequential local repro with source .envrc && PORT=4331 mix test --warnings-as-errors && CERBERUS_BROWSER_NAME=firefox PORT=4332 mix test --warnings-as-errors
- both halves passed locally: Chrome 619 tests, 0 failures; Firefox 619 tests, 0 failures
- the earlier GitHub failure was not reproducible after the Firefox parity fixes already in the tree; the remaining actionable change here was simplifying the workflow shape
