---
# cerberus-cxcv
title: Short-circuit browser locator assertions early-exit matching for browser locator assertions so assert_has/refute_has stop once the result is decided instead of collecting all candidates. Update focused assertion coverage and rerun targeted plus full gates. - [ ] inspect locator assertion matcher and identify safe early-exit cases - [ ] implement early-exit for assert/refute countless and bounded count assertions - [ ] rerun focused browser assertion/parity suites - [ ] run full cerberus gates and summarize impact - [ ] add summary and mark completed
status: scrapped
type: task
priority: normal
created_at: 2026-03-10T13:19:25Z
updated_at: 2026-03-10T13:22:33Z
---

Add early-exit matching for browser locator assertions so assert_has/refute_has stop once the result is decided instead of collecting all candidates.

- [ ] inspect locator assertion matcher and identify safe early-exit cases
- [ ] implement early-exit for assert/refute countless and bounded count assertions
- [ ] rerun focused browser assertion/parity suites
- [ ] run full cerberus gates and summarize impact
- [ ] add summary and mark completed

## Reasons for Scrapping

This drifted into browser assertion optimization, but the profiled EV2 hotspot is in the live/shared LazyHTML resolver path rather than browser assertions. Reverted the uncommitted browser helper change and returned to the live resolver work.
