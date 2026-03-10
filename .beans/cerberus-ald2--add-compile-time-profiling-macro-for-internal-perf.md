---
# cerberus-ald2
title: Add compile-time profiling macro for internal perf work
status: todo
type: task
created_at: 2026-03-10T09:33:28Z
updated_at: 2026-03-10T09:33:28Z
---

Keep internal performance instrumentation behind a compile-time macro, similar to Logger, so profiling can stay in hot paths without runtime cost when disabled. Scope: macro API, compile_env gate, migrate current ad-hoc profiling call sites if we decide to implement later.
