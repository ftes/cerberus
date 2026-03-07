---
# cerberus-08qf
title: Set EV2 Cerberus browser timeout to 4000ms
status: in-progress
type: task
priority: normal
created_at: 2026-03-07T06:40:32Z
updated_at: 2026-03-07T06:41:12Z
---

## Scope

- [ ] Add an EV2-only Cerberus browser timeout override of 4000ms in config/test.exs.
- [x] Confirm EV2 support helpers do not override browser timeout in a conflicting way.
- [ ] Run targeted migrated Cerberus browser tests in /Users/ftes/src/ev2-copy with random PORT values.
- [ ] Run one non-browser migrated EV2 test as a sanity check.

## Notes

Keep Cerberus library defaults unchanged.

## Blocker\n\nTargeted verification is currently blocked by an unrelated cerberus dependency compile failure in the shared workspace:\n- /Users/ftes/src/cerberus/lib/cerberus/html/html.ex:51\n- /Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_client.ex:166\n\nEV2 config change is in place, but the requested test runs cannot complete until those unrelated cerberus errors are resolved.
