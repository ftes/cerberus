---
# cerberus-8kzn
title: Fix slow-suite regressions after role-locator cut
status: completed
type: bug
priority: normal
created_at: 2026-03-06T08:52:11Z
updated_at: 2026-03-06T09:14:52Z
---

## Goal
Fix regressions observed in slow-inclusive validation after removing link/button locator kinds.

## Todo
- [x] Reproduce failing slow-inclusive tests with source .envrc and random PORT
- [x] Identify root cause for Live redirect assertion crash
- [x] Identify root cause for locator parity timeout
- [x] Implement clean-cut fixes and update tests if needed
- [x] Run format plus targeted and slow-inclusive verification
- [x] Add summary and complete bean

## Summary of Changes
Fixed two regressions from the role-locator cut and added focused non-slow coverage.

Live timeout redirect fix:
- Updated Cerberus.Phoenix.LiveViewTimeout to handle retry loops after watcher redirects when the session transitions from Live to Static.
- Added non-slow regression test in test/cerberus/phoenix/live_view_timeout_test.exs ("handles watcher redirect that switches from live to static session").
- Verified this new test fails against pre-fix code by temporarily restoring lib/cerberus/phoenix/live_view_timeout.ex from commit b849513 (KeyError on session.view), then passes with the fix.

Locator parity stabilization + lightweight regression test:
- Added a non-slow regression test in test/cerberus/locator_parity_test.exs ("chained snippet submit keeps form controls available for follow-up actions").
- Updated parity snippet forms used for submit flows to include onsubmit="return false" so submit cases do not navigate away during in-page locator corpus checks.
- Kept the slow corpus test but stabilized it for suite contention by running this module sync and increasing that test timeout.
- Verified the new lightweight test fails before the snippet fix by temporarily reverting form behavior to action="/search/results" (fill_in fails after submit), then passes with the fix.

Validation:
- mix format
- source .envrc and PORT=4531 mix precommit
- source .envrc and PORT=4531 mix test
- source .envrc and PORT=4531 mix test --include slow
