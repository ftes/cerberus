---
# cerberus-bg53
title: Investigate intermittent Dialyzer unknown_function warnings in deps
status: completed
type: task
priority: normal
created_at: 2026-03-03T22:01:19Z
updated_at: 2026-03-03T22:03:46Z
---

Investigate why dialyzer sometimes reports unknown_function and unknown_type for core modules in dependency files, then explain root cause and mitigation.

## Summary of Changes

- Confirmed Dialyzer config includes plt_add_apps with ex_unit and mix in mix.exs.
- Verified local runs of mix dialyzer and MIX_ENV=test mix dialyzer pass currently.
- Found multiple PLTs present for different OTP patch versions (28.3.1 and 28.3.3) across dev and test builds.
- Concluded intermittent unknown_function and unknown_type on core modules indicates stale, corrupt, or incompatible PLT usage (often from shared or concurrent _build state), not actual missing functions in deps.
