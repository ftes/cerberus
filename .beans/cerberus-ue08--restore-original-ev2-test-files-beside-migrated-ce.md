---
# cerberus-ue08
title: Restore original EV2 test files beside migrated Cerberus variants for more runtime comparisons
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:48:42Z
updated_at: 2026-03-09T18:51:41Z
---

Pick additional migrated EV2 tests that no longer have original counterparts, copy the current Cerberus versions to *_cerberus_test.exs, restore the original file contents from git history, and run side-by-side timing comparisons.

## Summary of Changes

Restored four additional original EV2 browser files from HEAD and kept the migrated Cerberus variants beside them as *_cerberus_test.exs:
- approve_timecards
- construction_rates
- create_offer
- invite_admin_without_offer

Measured sequential mix test reported times:
- approve_timecards: Playwright 4.9s vs Cerberus 5.9s
- construction_rates: Playwright 3.5s vs Cerberus 9.4s
- create_offer: Playwright 6.0s vs Cerberus 14.9s
- invite_admin_without_offer: Playwright 4.7s vs Cerberus 8.9s

Combined with the earlier comparisons:
- project_form_feature: Playwright 5.7s vs Cerberus 16.6s
- register_and_accept_offer: Playwright 4.4s vs Cerberus 19.6s
- notifications: PhoenixTest 2.2s vs Cerberus 13.5s
