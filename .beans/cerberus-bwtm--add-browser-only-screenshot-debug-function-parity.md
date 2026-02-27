---
# cerberus-bwtm
title: Add browser-only screenshot debug function parity
status: todo
type: task
priority: normal
created_at: 2026-02-27T19:55:35Z
updated_at: 2026-02-27T19:55:47Z
parent: cerberus-zqpu
blocking:
    - cerberus-rxqy
---

Add a dedicated screenshot function for browser-driven debug workflows and keep it explicitly browser-only.

## Scope
- Define screenshot API and options for browser sessions
- Implement screenshot in browser driver
- Return explicit unsupported errors in non-browser drivers
- Add browser integration coverage

## Done When
- [ ] Browser screenshot API is documented with options and outputs
- [ ] Browser driver captures screenshots reliably in tests
- [ ] Static and live drivers return explicit unsupported errors
- [ ] Browser integration tests cover representative screenshot flows
