---
# cerberus-0p9l
title: Add Cerberus.unwrap API parity slice
status: todo
type: task
priority: normal
created_at: 2026-02-27T19:47:04Z
updated_at: 2026-02-27T19:47:08Z
parent: cerberus-zqpu
---

## Scope
Add Cerberus.unwrap/1 API parity with PhoenixTest so callers can extract values from wrapped result terms in a predictable way.

## Notes
- Mirror PhoenixTest semantics and error behavior.
- Keep implementation simple and focused on the public API contract.

## Done When
- [ ] Cerberus.unwrap/1 is implemented with docs/specs.
- [ ] Tests cover success and failure/invalid-input behavior.
- [ ] Conformance notes mention parity intent vs PhoenixTest.
