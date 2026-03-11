---
# cerberus-usjn
title: Fix remaining EV2 dashboard Cerberus subset failure
status: completed
type: bug
priority: normal
created_at: 2026-03-10T19:26:51Z
updated_at: 2026-03-10T19:30:00Z
---

Investigate the remaining failing Cerberus-selected EV2 test in dashboard_live/index_cerberus_test.exs, compare it to the original PhoenixTest flow, fix the migrated copy or underlying Cerberus behavior as appropriate, rerun the EV2 Cerberus-selected subset, and record whether any remaining failures are separate sandbox ownership issues.

## Summary of Changes

Compared the remaining failing EV2 Cerberus dashboard copy to the original PhoenixTest flow and found that the failure was not sandbox ownership after all. The migrated `fails to accept with wrong secret` test had drifted from the original in two ways: it asserted exact `"4 attempt(s)"` text instead of the original substring match, and it tried to refute the Accept button before performing the final failing submit. Updated `/Users/ftes/src/ev2-copy/test/ev2_web/live/dashboard_live/index_cerberus_test.exs` to mirror the original sequence: inexact attempt-count assertions after each submit, then a fifth failing submit before `refute_has(button:Accept)`.

Verified the file in isolation and reran the full EV2 Cerberus-selected subset with `rg -l "@moduletag :cerberus|@tag :cerberus" test | sort | xargs mix test --only cerberus --max-cases 14`, which finished green at `169 tests, 0 failures, 4 skipped`.
