---
# cerberus-jpxh
title: Trim ev2-copy shim compat layer after upstream fixes
status: completed
type: task
priority: normal
created_at: 2026-03-05T20:35:11Z
updated_at: 2026-03-05T21:09:25Z
---

Audit ../ev2-copy shim compat helpers against current Cerberus.PhoenixTestShim support, remove unnecessary compat wrappers, and re-run affected tests.

- [ ] Identify wrappers now fully covered by Cerberus.PhoenixTestShim
- [ ] Remove low-risk redundant wrappers from ev2-copy compat
- [ ] Run targeted ev2-copy shim-using tests with random PORT
- [ ] Iterate on remaining wrappers based on failures
- [x] Document what still must remain in compat

## Summary of Changes

Validated additional compat-layer trimming in `../ev2-copy/test/support/ev2_web/phoenix_test_shim_compat.ex`.

- Removed and kept: `submit/1` fallback that auto-submitted `button[type=submit],input[type=submit]` when no active form existed.
- Tried and reverted: unwrap `:noproc` retry removal (caused reproducible LiveView `GenServer.call ... no process` failures in `message_new_test`).
- Tried and reverted: assertion timeout normalization removal (caused extra broad-suite timeouts for tests passing low `timeout` values, e.g. job titles/offer show assertions).

Validation runs used random ports with `.envrc` loaded (via direnv stdlib), including:
- broad non-Playwright PhoenixTest candidate slice (`810 tests`) after `submit/1` fallback removal
- targeted unwrap-heavy slice
- targeted timeout-sensitive slices
- targeted job titles + offer show recheck after revert

Remaining wrappers that still must stay for now:
- unwrap `:noproc` retry compatibility path
- assertion timeout floor (`ensure_assert_timeout/1`)
- existing click/upload/label-control fallbacks previously proven necessary


Final verification on the final state: broad non-Playwright PhoenixTest slice ended at `810 tests, 8 failures, 3 skipped`, matching the prior baseline failure count for this environment.
