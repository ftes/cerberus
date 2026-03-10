---
# cerberus-nhmj
title: Compact Chromium benchmark env var guards
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:44:06Z
updated_at: 2026-03-10T16:44:41Z
---

## Goal

Shorten the top-level CHROME and CHROMEDRIVER env var guards in the minimal Chromium benchmark back to single-line expressions.

## Todo

- [x] Compact the top-level env var guards
- [x] Run the benchmark with node@24 via mise
- [x] Add a summary and complete the bean

## Summary of Changes

Collapsed the top-level `CHROME` and `CHROMEDRIVER` guards in `bench/chromium_bidi_vs_cdp_evaluate.js` back to single-line constant expressions while keeping the same fail-fast behavior at module load.

Validated with `mise exec node@24 -- node bench/chromium_bidi_vs_cdp_evaluate.js`, producing:

```text
mode,mean_ms,median_ms,p95_ms
cdp,0.168,0.161,0.229
bidi,1.522,0.459,9.815

bidi_vs_cdp_mean_ratio=9.082x
bidi_vs_cdp_median_ratio=2.843x
```
