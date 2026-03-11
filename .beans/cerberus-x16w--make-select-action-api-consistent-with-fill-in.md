---
# cerberus-x16w
title: Make select action API consistent with fill_in
status: completed
type: task
priority: normal
created_at: 2026-03-11T11:53:04Z
updated_at: 2026-03-11T12:02:21Z
---

Replace keyword-only select option input with a positional option locator/value argument, update Cerberus callers/docs/tests, and update EV2 migrated copies to the simpler select shape.

## Summary of Changes

Changed the public select action API to use a positional option locator/value argument instead of option:. Added a public select_action_opts type/schema for the remaining keyword options, removed option:/exact_option from public docs and migrated Cerberus tests, docs, and EV2 Cerberus copy tests to the new shape. Verified targeted Cerberus select suites and the full EV2 Cerberus-tagged subset on the new API.
