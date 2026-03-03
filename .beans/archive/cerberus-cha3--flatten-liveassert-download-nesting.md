---
# cerberus-cha3
title: Flatten Live.assert_download nesting
status: completed
type: bug
priority: normal
created_at: 2026-03-03T22:03:56Z
updated_at: 2026-03-03T22:05:05Z
---

Address Credo function body nesting depth warning in Cerberus.Driver.Live.assert_download and commit the pending assert_download API slice.

## Summary of Changes

- Re-ran Credo on lib/cerberus/driver/live.ex and verified the nested-body warning is no longer present.
- Ran mix format before commit.
- Included the pending assert_download API/driver/docs/tests slice in the commit as requested.
