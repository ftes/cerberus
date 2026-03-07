---
# cerberus-b1tm
title: Browser select should trigger old-form client-side field state updates from EV2 timecard migration
status: scrapped
type: task
priority: normal
created_at: 2026-03-07T05:38:55Z
updated_at: 2026-03-07T05:49:58Z
---

## Reasons for Scrapping

This was not a Cerberus browser driver bug.

The migration failure came from incorrect assumptions in the EV2 test rewrite:
- the old timecard form uses timecard_data_* control ids
- the migrated browser assertions were targeting timecard_* ids and then a non-working label assumption for the dependent fields

Once the migrated test used the correct old-form control ids, test/features/my_timecards_browser_test.exs passed under Cerberus without browser-driver changes.
