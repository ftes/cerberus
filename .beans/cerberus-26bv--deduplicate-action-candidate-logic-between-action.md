---
# cerberus-26bv
title: Deduplicate action candidate logic between action_helpers and expressions
status: todo
type: task
priority: normal
created_at: 2026-03-03T11:32:12Z
updated_at: 2026-03-03T11:32:12Z
parent: cerberus-dsr0
---

Remove drift risk by defining one canonical candidate resolution and execution contract for browser actions.\n\nScope:\n- [ ] Remove duplicated candidate filtering and target selection logic across action_helpers.ex and expressions wrappers.\n- [ ] Keep one canonical helper API used by all action entrypoints.\n- [ ] Add tests that fail on semantic drift for candidate selection and target picking.
