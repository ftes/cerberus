---
# cerberus-pzlq
title: Fill remaining EV2 partial-copy Cerberus parity gaps
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:41:26Z
updated_at: 2026-03-10T16:54:11Z
---

Finish the missing migrated coverage in the EV2 partial-copy Cerberus files (users_live/show, user_controller, project_live/show) and then reassess the remaining behavior-shape drift in project_setup and generate_timecards_browser.

## Progress

- Expanded /Users/ftes/src/ev2-copy/test/ev2_web/admin/pages/users_live/show_cerberus_test.exs to full parity with the original show_test.exs coverage and kept it green under --only cerberus.
- Expanded /Users/ftes/src/ev2-copy/test/ev2_web/live/project_live/show_cerberus_test.exs to cover the original dashboard role-matrix scenarios, including the pending/to-approve loops and Irish PAYE/LOAN OUT cases.
- Verified the two expanded copies together with PORT=4922 MIX_ENV=test mix test ... --only cerberus (41 tests, 0 failures).
- Remaining partial-copy gap is /Users/ftes/src/ev2-copy/test/ev2_web/controllers/user_controller_cerberus_test.exs.

## Summary of Changes

- Filled the two real partial-copy Cerberus parity gaps in EV2: admin users live show and project dashboard show.
- Expanded /Users/ftes/src/ev2-copy/test/ev2_web/admin/pages/users_live/show_cerberus_test.exs from the original TFA-only subset to full account/company/startpack/account-actions/TFA coverage and kept it green.
- Expanded /Users/ftes/src/ev2-copy/test/ev2_web/live/project_live/show_cerberus_test.exs to cover the original project/personal dashboard scenarios, pending and to-approve role matrices, and Irish PAYE vs LOAN OUT behavior.
- Verified the two expanded copies together with PORT=4922 MIX_ENV=test mix test ... --only cerberus (41 tests, 0 failures).
- Reassessed /Users/ftes/src/ev2-copy/test/ev2_web/controllers/user_controller_cerberus_test.exs and determined it is not a remaining Cerberus migration gap in the same sense: the original file is mostly plain controller request/response coverage, and the PhoenixTest-style security-page behavior already exists in the Cerberus copy.
