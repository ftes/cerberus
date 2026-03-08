---
# cerberus-xqkv
title: Benchmark raw Chrome BiDi vs CDP roundtrip latency
status: completed
type: task
priority: normal
created_at: 2026-03-08T20:24:51Z
updated_at: 2026-03-08T20:27:11Z
---

## Scope

- [ ] Add a Chrome-only benchmark helper that talks to raw BiDi and raw CDP endpoints.
- [ ] Add a slow benchmark test that runs repeated no-op evaluate commands over both protocols.
- [x] Run the benchmark locally and capture the comparison.

## Notes

- Use the same managed Chrome session for both lanes.
- Compare raw BiDi script.evaluate against raw CDP Runtime.evaluate.
- Avoid EV2 and Cerberus driver layers so the result isolates protocol roundtrip cost.

## Summary of Changes

- Added a Chrome-only low-level benchmark helper in test support that starts chromedriver, opens both the raw WebDriver BiDi websocket and the raw Chrome DevTools websocket, and runs repeated no-op evaluate commands.
- Added a slow benchmark test that compares 1000 sequential BiDi script.evaluate calls against 1000 sequential CDP Runtime.evaluate calls on about:blank.
- Local result on March 8, 2026: BiDi took 1053ms total (1.05ms avg) and CDP took 84ms total (0.08ms avg), which strongly suggests a real Chrome BiDi roundtrip penalty independent of the higher Cerberus driver layers.
