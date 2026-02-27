---
# cerberus-okj5
title: Implement browser-oracle mismatch classification and reports
status: scrapped
type: task
priority: normal
created_at: 2026-02-27T07:41:41Z
updated_at: 2026-02-27T10:58:14Z
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

## Reasons for Scrapping

The team decided not to build mismatch classification/reporting right now. We will use direct test failures as the feedback loop and fix issues as they appear, which keeps the harness simpler and avoids maintaining an extra reporting layer.
