---
# cerberus-qny1
title: Limit live action retries to disabled controls
status: scrapped
type: task
priority: normal
created_at: 2026-03-10T07:27:56Z
updated_at: 2026-03-10T07:30:37Z
---

Change the live driver so actions resolve once against the current snapshot, act immediately if the target is present and enabled, and only enter the wait and retry path when the matched target is disabled. Do not retry generic not-found field or button resolutions by default.

## Reasons for Scrapping

Tried a thinner live-action path that only retried when a matched field or button was disabled and failed all generic not-found resolutions immediately. This kept the targeted live regression slice green, but it did not improve the preserved EV2 notifications_cerberus_test runtime. A warm rerun stayed around 14.4s, which was worse than the prior 13.4s row from the render-version document reuse change. The experiment was reverted instead of kept, because it changed live-driver semantics without buying measurable speed on the profiled downstream case.
