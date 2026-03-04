---
# cerberus-ztu3
title: Fix slow test include compile failure
status: in-progress
type: bug
created_at: 2026-03-04T18:37:24Z
updated_at: 2026-03-04T18:37:24Z
---

Reproduce and fix the failure when running MIX_ENV=test mix test --include slow, currently crashing with MatchError {:error, :enoent} during test compilation. Add/adjust coverage if needed and verify slow suite runs.
