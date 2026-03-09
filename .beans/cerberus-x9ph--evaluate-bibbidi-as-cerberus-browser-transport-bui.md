---
# cerberus-x9ph
title: Evaluate bibbidi as Cerberus browser transport building block
status: completed
type: task
priority: normal
created_at: 2026-03-09T08:00:21Z
updated_at: 2026-03-09T08:02:37Z
---

## Scope

- [x] Read the official bibbidi docs and local source to understand its browser/process/transport model.
- [x] Compare bibbidi's model against Cerberus's shared BiDi runtime plus per-test user-context/browsing-context architecture.
- [x] Estimate which Cerberus modules/code paths bibbidi could replace and which would still remain project-specific.
- [x] Summarize fit, risks, and likely code-savings with concrete file references.

## Notes

- Focus on Chrome-first browser support and current Cerberus browser runtime architecture.
- This is an evaluation task, not an implementation task.

## Summary of Changes

Cloned Bibbidi locally and compared its official docs/source against Cerberus browser internals. Conclusion: Bibbidi can fit only as a low-level BiDi websocket/command layer, roughly replacing Cerberus bidi.ex, bidi_socket.ex, and possibly ws.ex, but it does not replace Cerberus runtime launch, shared-supervision topology, per-test user-context/browsing-context lifecycle, readiness, or the browser action/assertion engine. Gross replaceable footprint is around 900 LOC out of about 9.8k browser-driver LOC; realistic net savings after adapter/supervision glue is closer to 500-700 LOC. Bibbidi's own Browser wrapper is Firefox-oriented and not a fit for Cerberus's ChromeDriver-based runtime model.
