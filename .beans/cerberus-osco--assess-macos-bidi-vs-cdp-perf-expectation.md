---
# cerberus-osco
title: Assess macOS BiDi vs CDP perf expectation
status: completed
type: task
priority: normal
created_at: 2026-03-08T20:50:28Z
updated_at: 2026-03-08T20:55:18Z
---

Question: given the Chromium BiDi benchmark, should Cerberus expect significant performance improvement from switching from BiDi to CDP on macOS?

- [x] Read the benchmark and note what it actually measures
- [x] Check Cerberus local protocol benchmarks and current driver hot paths
- [x] Summarize likely macOS impact and decision guidance

## Summary of Changes

- Read the upstream chromium-bidi benchmark docs and dashboard metadata. The project explicitly treats Ubuntu as the primary regression signal and calls out macOS as noisy/flaky for precise overhead measurement.
- Ran Cerberus's local raw Chrome protocol benchmark on this macOS machine. Results across five 1000-command runs were: BiDi 1054-1154ms total (1.054-1.154ms avg) vs CDP 85-91ms total (0.085-0.091ms avg), roughly a 12x protocol roundtrip gap for this no-op evaluate path.
- Confirmed in Cerberus runtime code that ChromeDriver is used for session/bootstrap, but the hot path already talks directly to the returned BiDi WebSocket URL and Chrome debugger WebSocket where applicable.
- Decision guidance: on macOS, switching evaluate-heavy hot paths from BiDi to CDP can deliver large wins; removing ChromeDriver while staying on BiDi is unlikely to materially improve steady-state command performance and would mostly affect startup/lifecycle complexity.
