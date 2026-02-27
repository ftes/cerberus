---
# cerberus-vzqq
title: Document easy switching between browser and non-browser tests as essential
status: completed
type: task
priority: normal
created_at: 2026-02-27T20:14:56Z
updated_at: 2026-02-27T20:17:22Z
---

## Context\nThe project plan/docs should explicitly state that easy switching between browser and non-browser based tests is an essential feature.\n\n## Todo\n- [x] Identify plan file(s) to update\n- [x] Update plan wording to mark easy browser/non-browser switching as essential\n- [x] Update documentation with same requirement\n- [x] Record summary of changes

## Summary of Changes
- Updated harness planning epic (cerberus-syh3) to state that easy switching between browser and non-browser modes is essential.
- Added corresponding README guidance in the Conformance Harness section so scenario logic stays driver-agnostic and only tags/session mode change when switching execution targets.
- Ran mix format after edits.

## Follow-up Refinement
- [x] Soften plan wording to allow targeted driver-specific logic like unwrap/2
- [x] Soften README wording with the same principle
- [x] Record refinement summary

## Follow-up Summary of Changes
- Refined plan wording to avoid a binary rule: prefer shared API for switchability, but allow minimal isolated driver-specific escape-hatch usage (for example unwrap/2).
- Refined README Conformance Harness wording with the same principle.
- Ran mix format after refinement edits.
