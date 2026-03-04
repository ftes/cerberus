---
# cerberus-yufn
title: Add not and has_not locator composition
status: todo
type: feature
created_at: 2026-03-04T08:13:44Z
updated_at: 2026-03-04T08:13:44Z
---

Introduce negative locator composition primitives not and has_not with clear semantics across static live and browser drivers.

Scope:
- [ ] Design API shapes for not and has_not that compose with and or has closest
- [ ] Implement normalization and matcher behavior for negation in all drivers
- [ ] Preserve readable diagnostics for positive and negative constraints
- [ ] Add docs examples covering boolean algebra patterns such as A and not B and not (A and B)
- [ ] Add focused tests for tricky boolean algebra and chaining precedence
- [ ] Add cross-driver parity tests and run format precommit
