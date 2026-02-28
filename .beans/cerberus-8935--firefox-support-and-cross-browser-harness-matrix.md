---
# cerberus-8935
title: Firefox support and cross-browser harness matrix
status: todo
type: task
priority: normal
created_at: 2026-02-28T07:07:18Z
updated_at: 2026-02-28T07:08:11Z
parent: cerberus-ykr0
---

Add Firefox support and include it in conformance/harness browser runs alongside existing supported browsers.

## Notes
- Public API target: support `session(:chrome)` and `session(:firefox)`.
- `session(:browser)` should remain supported and default to Chrome.
