---
# cerberus-okj5
title: Implement browser-oracle mismatch classification and reports
status: todo
type: task
created_at: 2026-02-27T07:41:41Z
updated_at: 2026-02-27T07:41:41Z
parent: cerberus-syh3
---

## Scope
Implement comparison layer that treats browser outcome as oracle for selected conformance suites.

## Classification Categories
- visibility semantics mismatch
- whitespace normalization mismatch
- exact/substring mismatch
- count/order mismatch
- navigation/path timing mismatch

## Deliverables
- structured mismatch object
- terminal reporter with grouped sections
- optional JSON output for CI artifacts

## Done When
- [ ] at least 1 intentional mismatch fixture is correctly classified.
- [ ] report includes reproducible scenario id + locator + options.
