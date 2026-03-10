---
# cerberus-rayd
title: Rewrite Chromium benchmark for Node 24
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:36:33Z
updated_at: 2026-03-10T16:38:04Z
---

## Goal

Replace the standalone Chromium BiDi vs CDP evaluate benchmark with a clean Node 24-only implementation using built-in fetch and WebSocket.

## Todo

- [x] Rewrite the benchmark for Node 24 built-ins
- [x] Run the benchmark with node@24 via mise
- [x] Add a summary and complete the bean

## Summary of Changes

Replaced `bench/chromium_bidi_vs_cdp_evaluate.js` with a clean Node 24-only implementation that uses built-in `fetch` and `WebSocket`, removing the custom HTTP client and manual websocket framing code.

The script is now 269 lines and was validated with `mise exec node@24 -- node ... --iterations 200 --warmup 30`. Result on this machine:

```text
mode,mean_ms,median_ms,p95_ms
cdp,0.229,0.181,0.256
bidi,1.453,0.477,9.956

bidi_vs_cdp_mean_ratio=6.335x
bidi_vs_cdp_median_ratio=2.644x
```
