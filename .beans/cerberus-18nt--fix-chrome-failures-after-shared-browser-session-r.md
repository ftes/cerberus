---
# cerberus-18nt
title: Fix chrome failures after shared-browser-session rollout
status: completed
type: bug
priority: normal
created_at: 2026-03-03T11:03:49Z
updated_at: 2026-03-03T11:13:13Z
---

Investigate and fix newly observed Chrome failures/flakiness after shared browser session conversion.\n\nScope:\n- [x] Reproduce failing Chrome tests and identify failure clusters\n- [x] Patch tests/helpers to restore deterministic isolation where needed\n- [x] Run targeted + full browser validation\n- [x] Commit code + bean

## Summary of Changes

- Reproduced Chrome failures and isolated them to browser submit target resolution (wrong button clicked when non-submit buttons were present before submit buttons) and outdated config test expectations.
- Fixed `ActionHelpers.submitCandidates` to preserve original DOM button indexes instead of reindexing filtered submit controls, aligning resolver output with execution lookup.
- Bumped browser action helper preload script version from 2 to 3 so updated helper logic is not skipped in-page.
- Updated browser config tests to account for `ActionHelpers.preload_script()` being included in browser context init scripts.
- Validation: targeted failing suites all pass and full Chrome run passes (`mix test test/cerberus`: 373 tests, 0 failures).
