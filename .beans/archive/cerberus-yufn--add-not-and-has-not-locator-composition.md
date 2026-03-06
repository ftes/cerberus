---
# cerberus-yufn
title: Add not and has_not locator composition
status: completed
type: feature
priority: normal
created_at: 2026-03-04T08:13:44Z
updated_at: 2026-03-04T08:35:50Z
---

Introduce negative locator composition primitives not and has_not with clear semantics across static live and browser drivers.

Scope:
- [x] Design API shapes for not and has_not that compose with and or has closest
- [x] Implement normalization and matcher behavior for negation in all drivers
- [x] Preserve readable diagnostics for positive and negative constraints
- [x] Add docs examples covering boolean algebra patterns such as A and not B and not (A and B)
- [x] Add focused tests for tricky boolean algebra and chaining precedence
- [x] Add cross-driver parity tests and run format precommit

## Summary of Changes
- Added `not_` and `has_not` locator primitives to public Cerberus API and locator normalization (`Cerberus`, `Cerberus.Locator`).
- Extended locator AST/composition to support `:not` across map/keyword helper forms and chaining (`A and not B`, `not(A and B)`).
- Implemented `has_not`/`:not` matching in static/live/browser matching paths (`Cerberus.Html`, browser action helper JS payload matching, and live clickable matching).
- Preserved assertion diagnostics and updated assertion guardrails so `assert_has/refute_has` continue rejecting unsupported composed/has filters in this slice.
- Added focused tests for locator normalization and boolean composition plus cross-driver behavior/parity coverage (`locator_test`, `helper_locator_behavior_test`, `locator_parity_test`).
- Updated docs (`README`, getting-started, cheatsheet) with boolean algebra and `has_not` examples.
- Ran `mix format`, targeted tests, and `mix precommit` successfully.
