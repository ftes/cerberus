---
# cerberus-kced
title: Investigate EV2 Week ending day wrong option selection
status: completed
type: bug
priority: normal
created_at: 2026-03-05T06:07:40Z
updated_at: 2026-03-05T06:14:30Z
---

EV2 Cerberus migrated test appears to select Monday instead of Sunday for Week ending day compared with original PhoenixTest behavior.

## Todo

- [x] Compare failing Cerberus and original PhoenixTest tests at reported lines
- [x] Reproduce/trace select handling path for Week ending day in live/static driver
- [x] Identify whether mismatch occurs on page load, select submission, or assertion matching
- [x] Implement fix with regression coverage (if bug confirmed)
- [x] Run format + targeted tests and summarize findings

## Summary of Changes

- Compared EV2 original and Cerberus-migrated tests and reproduced the failure at show_test_cerberus.exs:242.
- Traced the failure to Cerberus Html.form_defaults select handling during form phx-change: selected <option> detection incorrectly looked for checked instead of selected.
- This caused untouched select fields to fall back to first enabled option (Monday), mutating week_ending_day on first select change and triggering validation error: Deadline must be day after weekending day.
- Fixed option selection detection in Cerberus.Html by reading the selected attribute for options.
- Added regression test coverage in Cerberus.HtmlTest to ensure form_defaults preserves selected option values for selects.
- Verified with targeted Cerberus tests and reran the exact failing EV2 test, which now passes.
