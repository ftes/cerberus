---
# cerberus-01bj
title: Handle no-push recipient toggles in EV2 shim flow
status: scrapped
type: bug
priority: normal
created_at: 2026-03-05T12:39:56Z
updated_at: 2026-03-06T20:22:35Z
---

EV2-copy: message_new_test re-order existing recipients is currently skipped. Cerberus shim cannot reliably toggle recipient checkboxes in add-from-groups flow when no form-field locator resolves and click path has no push/nav command.

## Reasons for Scrapping
- Cerberus/PhoenixTest shim flows have been removed, so this shim-specific follow-up no longer has a valid execution path.
- Any remaining EV2 recipient toggle issues should be tracked against direct Cerberus migration coverage instead of shim compatibility.
