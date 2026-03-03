---
# cerberus-85s7
title: Validate qz5y impact on performance recommendations
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:19:06Z
updated_at: 2026-03-03T14:19:54Z
---

Goal: verify whether qz5y invalidates prior top-4 performance suggestions.

## Todo
- [x] Inspect qz5y implementation in browser driver code
- [x] Map qz5y changes against the 4 recommendations
- [x] Summarize which suggestions remain valid, need revision, or are obsolete

## Summary of Changes
- Reviewed `cerberus-qz5y` bean scope and resulting browser driver code (`eval_json_with_transient_retry`, transient navigation error classifier, assertion/path retry wrapping, transient read wrappers).
- Checked qz5y against the 4 performance suggestions from prior profiling.

### Impact of qz5y on the 4 suggestions
1) Conditional `await_ready` for non-navigation form actions:
- Status: still valid.
- qz5y does not change `await_driver_ready` call frequency for action results.

2) Collapse action execution + settle detection into one roundtrip:
- Status: still valid.
- qz5y adds retry around eval failures but does not fuse action eval + readiness wait.

3) `visit` fast path for same-path no-op navigations:
- Status: still valid.
- qz5y does not change `visit` behavior or add no-op navigation short-circuit.

4) Batch adjacent text assertions into one evaluation:
- Status: still valid, but should preserve per-assertion diagnostics semantics.
- qz5y already retries assertion evals on transient navigation/context errors; batching would still reduce overall roundtrips and retry exposure.

### Conclusion
- None of the 4 suggestions are invalidated by qz5y.
- qz5y improves resilience for transient failures; it does not materially reduce the dominant wait buckets identified in profiling.
