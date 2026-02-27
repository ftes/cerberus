---
# cerberus-rxqy
title: Browser-only extensions parity slice
status: todo
type: task
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T11:00:49Z
parent: cerberus-zqpu
---

## Scope
Add browser-only capability group inspired by PhoenixTest.Playwright for richer real-browser workflows.

## Capability Group
- screenshot
- keyboard helpers (type, press)
- drag interactions
- dialog handling helper (with_dialog pattern)
- cookie/session-cookie inspection helpers

## Notes
- Keep these APIs explicitly browser-driver scoped with clear unsupported errors elsewhere.
- Validate behavior with browser integration tests only.

## Done When
- [ ] Browser driver implements the grouped capabilities with docs.
- [ ] Non-browser drivers return explicit unsupported errors.
- [ ] Integration tests demonstrate at least screenshot + keyboard + dialog handling flows.
