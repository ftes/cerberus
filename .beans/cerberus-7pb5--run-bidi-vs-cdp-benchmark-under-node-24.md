---
# cerberus-7pb5
title: Run BiDi vs CDP benchmark under Node 24
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:28:02Z
updated_at: 2026-03-10T16:28:42Z
---

## Goal

Rerun the standalone Chromium BiDi vs CDP evaluate benchmark using Node 24 via mise and record the output.

## Todo

- [x] Run the benchmark with node@24 via mise
- [x] Record the output and complete the bean

## Summary of Changes

Ran `bench/chromium_bidi_vs_cdp_evaluate.js` with `mise exec node@24 -- node ...` using Node `v24.13.0`.

Result for `--iterations 200 --warmup 30`:

```text
mode,mean_ms,median_ms,p95_ms
cdp,0.189,0.153,0.220
bidi,1.526,0.464,2.455

bidi_vs_cdp_mean_ratio=8.084x
bidi_vs_cdp_median_ratio=3.037x
```
