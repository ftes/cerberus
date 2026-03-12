---
# cerberus-zbdp
title: Investigate EV2 CI run 66694853197 failures
status: completed
type: bug
priority: normal
created_at: 2026-03-11T20:47:24Z
updated_at: 2026-03-11T20:49:09Z
---

Investigate the 15 failures in GitHub Actions run 66694853197, classify their root causes, and determine whether they map to recent Cerberus changes or separate drift.

- [x] fetch the CI run details and failing test list
- [x] group failures by root cause and identify likely fixes
- [x] summarize findings and mark bean completed if no code changes are needed

## Summary of Changes

Fetched the actual failing workflow run `22973111935` and mapped the provided `66694853197` number to the failing job id (`Tests`). Classified the 15 failures into: 4 Playwright tests incorrectly included in the compare-copy lane before the local alias fix; 2 distro upload failures caused by hardcoded local absolute fixture paths; 2 inactivity modal failures caused by scoping into a hidden modal container; 1 timeout unrelated to Cerberus assertions (an ExUnit 60s timeout in `TimecardDataControllerCerberusTest`); and several remaining Cerberus browser copy failures that still need targeted fixes (`InviteAdminWithoutOfferCerberusTest`, `CreateOfferCerberusTest`, `GenerateTimecardsBrowserCerberusTest`, `ConstructionRatesCerberusTest`).
