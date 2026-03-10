---
# cerberus-ha0t
title: Shorten Chromium issue repro script
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:22:50Z
updated_at: 2026-03-10T16:25:10Z
---

## Goal

Reduce the size of the standalone BiDi vs CDP evaluate repro script while preserving the same benchmark behavior.

## Todo

- [x] Review the current script and identify removable complexity
- [x] Replace the script with a shorter equivalent implementation
- [x] Run the shortened script locally and verify output
- [x] Add a summary and complete the bean

## Summary of Changes

Rewrote `bench/chromium_bidi_vs_cdp_evaluate.js` to focus only on the Chromium issue repro path: one fixed ChromeDriver launch path, one BiDi socket, one CDP socket, fixed benchmark defaults, and a smaller output format.

The script was reduced from 895 lines to 367 lines while preserving the same core measurement. Verified locally with a 200-iteration run that still shows a substantial BiDi evaluate slowdown versus CDP (about 0.216ms mean for CDP vs 1.768ms mean for BiDi on this machine).
