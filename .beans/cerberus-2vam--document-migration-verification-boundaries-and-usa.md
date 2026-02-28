---
# cerberus-2vam
title: Document migration verification boundaries and usage
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:47:02Z
updated_at: 2026-02-28T14:02:34Z
parent: cerberus-it5x
---

Document how to run the migration verification loop, what API/options are covered, and which boundaries are intentionally out of scope.

## Summary of Changes
- Added a dedicated guide at docs/migration-verification.md covering execution flow, parity report fields, CI wiring, and explicit scope boundaries.
- Linked migration verification usage/boundaries from README migration section.
- Added the new guide to ExDoc extras/groups and cross-linked it from the migration verification matrix.
- Updated the matrix checklist to reflect that CI now includes row-level parity reporting.
