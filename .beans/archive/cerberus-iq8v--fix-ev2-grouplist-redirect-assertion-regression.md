---
# cerberus-iq8v
title: Fix EV2 GroupList redirect assertion regression
status: completed
type: bug
priority: normal
created_at: 2026-03-04T19:53:55Z
updated_at: 2026-03-04T20:29:07Z
---

Reproduce failing Ev2Web.Live.DistroLive.GroupListTest after Cerberus assertion API changes, identify whether LiveView timeout redirect fallback is misfiring, and patch Cerberus so EV2 test passes without changing app test intent.

## Summary of Changes

- Restored PhoenixTest-style timeout redirect fallback (`assert_redirect`) in Cerberus LiveView timeout handling.
- Fixed Live redirect follow to preserve flash across redirects by setting the signed `__phoenix_flash__` cookie before request follow.
- Fixed Live patch-path probing to avoid consuming redirect/navigation mailbox messages (`read_patch_path/1` now receives only `:patch` events).
- Added resilient `open_browser/2` behavior for live sessions: use LiveView delegation when the view PID is alive, otherwise fall back to snapshot HTML file output.
- Verified the EV2 repro test (`group_list_test` line 105) passes with Cerberus after these fixes.
