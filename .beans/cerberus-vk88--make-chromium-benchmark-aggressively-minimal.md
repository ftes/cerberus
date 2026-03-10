---
# cerberus-vk88
title: Make Chromium benchmark aggressively minimal
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:40:31Z
updated_at: 2026-03-10T16:41:41Z
---

## Goal

Reduce the Node 24 Chromium BiDi vs CDP benchmark further by hardcoding settings, keeping one helper, inlining setup, and dropping most cleanup/error handling.

## Todo

- [x] Rewrite the script to the requested minimal shape
- [x] Run it with node@24 via mise
- [x] Add a summary and complete the bean

## Summary of Changes

Reduced `bench/chromium_bidi_vs_cdp_evaluate.js` to an aggressively minimal Node 24-only form: fixed top-level constants, one `rpc` helper, inlined setup flow, fixed ChromeDriver port, and best-effort cleanup only.

The file is now 192 lines. Verified with `mise exec node@24 -- node bench/chromium_bidi_vs_cdp_evaluate.js`, producing:

```text
mode,mean_ms,median_ms,p95_ms
cdp,0.253,0.186,0.278
bidi,1.634,0.504,14.146

bidi_vs_cdp_mean_ratio=6.456x
bidi_vs_cdp_median_ratio=2.707x
```
