---
# cerberus-o6e5
title: Fix compare-copy CI failures from run 22973111935
status: in-progress
type: bug
priority: normal
created_at: 2026-03-11T20:52:06Z
updated_at: 2026-03-12T06:48:29Z
---

Fix the actionable compare-copy failures from GitHub Actions run 22973111935 in EV2.

- [x] confirm current EV2 worktree state and affected files
- [ ] fix copied-test issues (alias selection, fixture paths, inactivity modal scope)
- [x] rerun focused Cerberus compare-copy files with random PORTs
- [x] investigate and fix remaining Cerberus-native failures
- [ ] summarize changes and mark bean completed if all targeted failures are handled

## Notes

- Added a Cerberus-side fix so expired internal locator-count deadlines in static/live drivers now surface as a normal assertion-timeout reason instead of leaking a raw `{:cerberus_assertion_deadline_exceeded, ...}` throw tuple.
- Verified locally in `ev2-copy` that `test/ev2_web/admin/pages/job_titles_live/index_cerberus_test.exs` still passes against the patched local Cerberus checkout, so the remaining CI-only failure there still looks like a performance-margin issue under suite load rather than a local deterministic functional failure.
- Verified locally that `test/features/construction_rates_cerberus_test.exs` passes when `CHROME` and `CHROMEDRIVER` are wired in from the Cerberus runtime install.
