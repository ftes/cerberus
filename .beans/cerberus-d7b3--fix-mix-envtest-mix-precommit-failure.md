---
# cerberus-d7b3
title: Fix MIX_ENV=test mix precommit failure
status: completed
type: bug
priority: normal
created_at: 2026-03-06T11:41:33Z
updated_at: 2026-03-06T11:46:09Z
---

## Goal
Resolve the current failing check in MIX_ENV=test mix precommit.

## Todo
- [x] Reproduce failing precommit locally
- [x] Implement minimal code fix
- [x] Run format and targeted verification
- [x] Run full precommit to confirm green
- [x] Record summary of changes

## Summary of Changes
- Fixed Credo line-length issues in assertions by introducing an is_value_expected guard and wrapping a long profile_driver_operation call.
- Fixed Credo nesting-depth issues in static and live value assertions by computing assertion operation via helper function instead of nested inline conditionals.
- Fixed Dialyzer contract warning in Phoenix fixture controller by changing put_layout plug args to the expected format-keyed keyword list.
- Verified with targeted tests and a full source .envrc plus PORT=4077 MIX_ENV=test mix precommit run, which now passes.
