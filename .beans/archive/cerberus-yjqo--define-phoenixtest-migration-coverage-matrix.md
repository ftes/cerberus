---
# cerberus-yjqo
title: Define PhoenixTest migration coverage matrix
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:44:43Z
updated_at: 2026-02-28T08:46:22Z
parent: cerberus-it5x
---

Create a concrete API and option coverage matrix for PhoenixTest and PhoenixTestPlaywright migration verification, mapping each function/option family to fixture scenarios and expected pre/post migration assertions.

## Summary of Changes

- Added `docs/migration-verification-matrix.md` with a concrete API/option coverage matrix for PhoenixTest and PhoenixTestPlaywright migration verification.
- Split matrix by core PhoenixTest, LiveView-specific, and Playwright/browser-only families with representative option coverage.
- Added fixture scenario identifiers and pre/post migration assertions per row to guide deterministic verification implementation.
- Added a scenario completion checklist for before/after migration parity execution.
- Linked the matrix from README and ExDoc extras for discoverability.
