---
# cerberus-y8iy
title: Hoist Chromium benchmark env vars to top-level constants
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:42:21Z
updated_at: 2026-03-10T16:42:58Z
---

## Goal

Update the minimal Node 24 Chromium benchmark so the CHROME and CHROMEDRIVER env vars are required at top-level constant initialization.

## Todo

- [x] Move CHROME and CHROMEDRIVER env resolution to top-level constants
- [x] Run the benchmark with node@24 via mise
- [x] Add a summary and complete the bean

## Summary of Changes

Updated `bench/chromium_bidi_vs_cdp_evaluate.js` so `CHROME` and `CHROMEDRIVER` are required as top-level constants and fail immediately at module load when missing. The fixed ChromeDriver port remains a top-level constant as well.

Validated with `mise exec node@24 -- node bench/chromium_bidi_vs_cdp_evaluate.js`, producing:

```text
mode,mean_ms,median_ms,p95_ms
cdp,0.201,0.184,0.240
bidi,1.579,0.485,12.294

bidi_vs_cdp_mean_ratio=7.843x
bidi_vs_cdp_median_ratio=2.637x
```
