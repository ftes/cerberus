---
# cerberus-3nrz
title: Move path assertions to single in-browser wait loop
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T12:16:57Z
parent: cerberus-dsr0
---

Replace Elixir recursive orchestration for path assertions with one browser-side polling loop per assertion call.\n\nScope:\n- [ ] Keep exact, query, and regex path semantics unchanged.\n- [ ] Return consistent diagnostics and timeout reasons.\n- [ ] Validate stability and lower roundtrips on chrome and firefox.
