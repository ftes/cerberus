---
# cerberus-qshc
title: Remove test harness and convert to explicit driver loops
status: todo
type: task
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T17:33:28Z
parent: cerberus-whq9
---

Phase 3: Replace Harness.run/run! usage with plain ExUnit patterns.

Goals:
- Remove test/support/harness.ex and related tag-driven matrix behavior.
- Use explicit for driver in ... loops where multi-driver coverage is needed.

## Todo
- [ ] Inventory and replace all Harness.run/run! call sites
- [ ] Convert cross-driver scenarios to explicit loop-generated tests
- [ ] Remove harness support code and obsolete tags
- [ ] Run format and precommit
