---
# cerberus-u0g3
title: Fix remaining EV2 migrated Cerberus copy failures the concrete migrated EV2 Cerberus copy failures that still break the downstream cerbrerus subset, starting with create_offer_cerberus_test helper/session bugs and then rerunning the migrated subset to separate real test failures from sandbox fallout.
status: completed
type: bug
priority: normal
created_at: 2026-03-10T16:07:59Z
updated_at: 2026-03-10T16:29:04Z
---

Fix

## Progress

- Fixed create_offer_cerberus_test helper/session bug by changing test/support/cerberus.ex select_job_title/2 to preserve the Cerberus session via Browser.with_evaluate_js/3.
- Verified test/features/create_offer_cerberus_test.exs now passes on its own (6 tests, 0 failures).
- Verified the previous full-suite command mix test --only cerbrerus --include integration was too broad: it also runs original integration-tagged Playwright files, so it is not a valid migrated-only check.
- Reran the actual migrated file set by explicit cerbrerus file list with --max-cases 14.
- Current real migrated-scope status: 177 tests, 1 failure, 4 skipped.
- Remaining failure is suite-only in test/features/construction_rates_cerberus_test.exs setup under async load, with DBConnection timeout/owner-lifetime symptoms while company_user_fixture/1 is creating data.
- Increasing ecto_sandbox_stop_owner_delay to 1000ms and Repo pool_size to 20 in config/test.exs did not eliminate that remaining failure.

## Summary of Changes

- Fixed the `select_job_title/2` Cerberus helper to preserve the Cerberus session via `Browser.with_evaluate_js/3`, which resolved the deterministic helper/session breakage in `create_offer_cerberus_test`.
- Verified `create_offer_cerberus_test.exs` passes on its own after the helper fix.
- Confirmed the earlier `--only cerberus --include integration` command was invalid for downstream verification because it also selected original Playwright integration tests.
- Reran the actual Cerberus-copy file set and isolated the remaining failures to suite-only async DB/sandbox pressure in the heaviest browser-copy modules.
- Stabilized the remaining downstream failures by making `register_and_accept_offer_cerberus_test.exs` and `construction_rates_cerberus_test.exs` run with `async: false`, which made the Cerberus-only EV2 subset pass under the intended selection path.
