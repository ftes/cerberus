---
# cerberus-bfji
title: Add open_browser debug function across static, live, and browser drivers
status: todo
type: task
priority: normal
created_at: 2026-02-27T19:55:35Z
updated_at: 2026-02-27T19:55:39Z
parent: cerberus-zqpu
---

Implement an open_browser helper for dev and debug workflows with consistent API shape across all drivers, following PhoenixTest conventions.

## Scope
- Define shared API contract and return semantics for open_browser
- Implement behavior for static driver
- Implement behavior for live driver
- Implement behavior for browser driver

## Done When
- [ ] Public API and docs define open_browser semantics clearly
- [ ] Static, live, and browser drivers support open_browser with consistent behavior
- [ ] Tests cover cross-driver behavior and error cases
- [ ] Harness coverage validates no semantic drift between drivers
