---
# cerberus-ald2
title: Add compile-time profiling macro for internal perf work
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T09:33:28Z
updated_at: 2026-03-10T11:22:27Z
---

Keep internal performance instrumentation behind a compile-time macro, similar to Logger, so profiling can stay in hot paths without runtime cost when disabled. Scope: macro API, compile_env gate, migrate current ad-hoc profiling call sites if we decide to implement later.


## Plan

- add a compile-time profiling macro that compiles away entirely when profiling is disabled
- instrument the live driver at the action and resolver boundaries we are currently guessing about: click, submit, fill_in, check, uncheck, resolve_form_field, resolve_submit_button, resolve_clickable_button, and any remaining document refresh path
- run the preserved EV2 notifications Cerberus row with profiling enabled to identify exact hot buckets after the latest shared resolver rewrite
- use that output to decide the next clean-cut simplification instead of adding speculative fast paths

## Notes
- deeper profiling showed the expensive shared button path was not accessible-name extraction; it was unconditional state computation in action_node_matches_common_opts/3
- compile-time profiling remains useful and low-cost: the latest run identified the exact hot bucket without leaving runtime overhead when disabled
