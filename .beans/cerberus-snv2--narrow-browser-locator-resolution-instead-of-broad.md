---
# cerberus-snv2
title: Narrow browser locator resolution instead of broad candidate scans
status: todo
type: task
created_at: 2026-03-08T19:34:57Z
updated_at: 2026-03-08T19:34:57Z
---

## Scope

- [ ] Replace broad candidate-first browser locator resolution with narrower selector-driven resolution where possible.
- [ ] Preserve current Cerberus locator semantics.
- [ ] Re-measure EV2 browser comparison rows after the refactor.

## Notes

- Deferred from the current EV2 performance investigation.
- Current evidence suggests this is worth pursuing later, but it is not yet proven to be the dominant remaining gap.
- Keep this separate from transport/protocol timing work so the next optimization is based on measured evidence.
