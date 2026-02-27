---
# cerberus-rxqy
title: Browser-only extensions parity slice
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T21:18:54Z
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
- JavaScript evaluation helpers (evaluate_js parity)
- cookie mutation helpers (add_cookie parity)

## Notes
- Keep these APIs explicitly browser-driver scoped with clear unsupported errors elsewhere.
- Keep advanced APIs on the Browser module only; do not expose them on top-level Cerberus.
- Validate behavior with browser integration tests only.

## Done When
- [ ] Browser driver implements the grouped capabilities with docs.
- [ ] Non-browser drivers return explicit unsupported errors.
- [ ] Integration tests demonstrate at least screenshot + keyboard + dialog handling flows.
- [ ] Integration tests cover evaluate_js and add_cookie parity semantics.
