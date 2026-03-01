---
# cerberus-a940
title: Benchmark browser assertion helper locator paths
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:30:31Z
updated_at: 2026-03-01T20:56:34Z
parent: cerberus-d2lg
---

Add a repeatable benchmark harness for browser assertion helper (text/label/link/button/placeholder/title/alt/testid) on synthetic DOM sizes. Capture baseline vs optimized timings and set regression thresholds for CI/local profiling.

## Summary of Changes

- Added a simple repeatable benchmark script at test/bench/browser_locator_assertion_paths_benchmark.exs.
- Script measures browser assert_has locator paths (text, label, link, button, placeholder, title, alt, testid) against synthetic DOM sizes.
- Run command:
  - MIX_ENV=test mix run test/bench/browser_locator_assertion_paths_benchmark.exs --sizes 200,1000 --iterations 12 --warmup 3
- Captured baseline medians (ms):
  - size 200: text 5.334, label 1.682, link 1.509, button 1.107, placeholder 1.028, title 0.956, alt 1.705, testid 0.808
  - size 1000: text 18.107, label 3.054, link 3.903, button 3.280, placeholder 2.322, title 2.321, alt 6.733, testid 2.322
