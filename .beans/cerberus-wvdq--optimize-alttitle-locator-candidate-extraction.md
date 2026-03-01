---
# cerberus-wvdq
title: Optimize alt/title locator candidate extraction
status: todo
type: task
created_at: 2026-03-01T17:30:38Z
updated_at: 2026-03-01T17:30:38Z
parent: cerberus-d2lg
---

Further optimize browser assertion helper for alt/title matching: avoid broad subtree scans, add strict candidate preselectors, and cache nested alt resolution per assertion pass without changing semantics across static/live/browser drivers.
