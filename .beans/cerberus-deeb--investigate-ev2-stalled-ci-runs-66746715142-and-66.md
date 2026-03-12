---
# cerberus-deeb
title: Investigate EV2 stalled CI runs 66746715142 and 66694853197
status: completed
type: bug
priority: normal
created_at: 2026-03-12T06:32:55Z
updated_at: 2026-03-12T06:35:51Z
---

## Todo

- [x] Inspect current stalled GitHub Actions run 66746715142
- [x] Compare with previous long-running job 66694853197 / run 22973111935
- [x] Correlate the stall pattern with Cerberus browser runtime behavior
- [x] Summarize likely causes and next checks

## Summary of Changes

- Fetched the GitHub Actions metadata and failed-step logs for job `66746715142` (run `22989344060`) and compared them with job `66694853197` in run `22973111935`.
- Confirmed both jobs spent nearly all of their runtime inside the single `Cerberus compare copy` step rather than stalling during setup or teardown.
- Determined that the newer run was mostly a quiet but progressing ExUnit step with only three failures, while the older run also included a genuine 60-second ExUnit timeout (`TimecardDataControllerCerberusTest`) plus broader compare-lane drift.
- Identified the most suspicious Cerberus-internal new failure signature as the immediate negative assertion-deadline throw from `Cerberus.Html.assert_deadline!/0`, which explains a fast failure but not the apparent CI stall.
