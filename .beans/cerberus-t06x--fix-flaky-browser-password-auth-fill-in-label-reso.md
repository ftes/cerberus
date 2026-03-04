---
# cerberus-t06x
title: Fix flaky browser password auth fill_in label resolution
status: completed
type: bug
priority: normal
created_at: 2026-03-04T21:42:01Z
updated_at: 2026-03-04T21:45:08Z
---

## Goal
Fix intermittent browser password auth flow failure where fill_in(label("Email"), ...) cannot find a matching field on auth dashboard routes.

## Tasks
- [x] Reproduce failure deterministically or with repeated runs
- [x] Identify root cause in browser field candidate resolution or auth navigation timing
- [x] Implement robust fix with regression coverage
- [x] Verify with repeated targeted runs

## Summary of Changes
- Reproduced deterministically with `test/cerberus/password_auth_flow_test.exs --seed 1`.
- Root cause: `live click supports inexact submit button text matching (browser)` ended while authenticated. Because the module uses a shared browser session, later browser auth tests could start with an existing auth cookie and get redirected to dashboard, making `fill_in(label("Email"), ...)` fail.
- Fix: updated that test to log out at the end and assert redirect to `/auth/live/users/log_in`.
- Verification:
  - `PORT=4481 mix test test/cerberus/password_auth_flow_test.exs --seed 1`
  - `PORT=4482 mix test test/cerberus/password_auth_flow_test.exs --seed 2`
  - `PORT=4483 mix test test/cerberus/password_auth_flow_test.exs --seed 3`
  - `for s in 1 4 7 11 19; do PORT=$((4500+s)) mix test test/cerberus/password_auth_flow_test.exs --seed $s --max-failures 1; done`
