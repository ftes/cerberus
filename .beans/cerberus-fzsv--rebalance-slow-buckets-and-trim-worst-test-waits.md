---
# cerberus-fzsv
title: Rebalance slow buckets and trim worst test waits
status: completed
type: task
priority: normal
created_at: 2026-03-09T10:55:41Z
updated_at: 2026-03-09T11:08:36Z
---

## Scope

- [ ] Inspect the current slowest regular and slow-tagged tests and classify them as optimize vs re-tag.
- [ ] Move obviously long-running contract/timeout tests into the slow bucket where appropriate.
- [ ] Reduce avoidable waits in the worst slow tests without weakening coverage.
- [x] Re-run slowest regular and slow lanes and record before/after timings.

## Summary of Changes

- Rebalanced bucket placement for tests that are intentionally broad browser/live contract coverage rather than fast-path regression checks.
- Moved these rows into the slow bucket:
  - BrowserExtensionsTest screenshot + keyboard + dialog + drag browser extensions work together
  - BrowserExtensionsTest press uses real keyboard semantics for printable keys, editing keys, and Tab focus traversal
  - CrossDriverMultiTabUserTest browser variant
  - LiveCheckboxBehaviorTest label-based nameless checkbox phx-click sends value payloads
- Reduced avoidable time in regular/slow contract rows by switching locator-heavy failure-path assertions to direct CSS locators where label semantics were not under test.
- Reduced the browser action settle long-budget fixture delays.

## Before/After Notes

- Regular lane notable changes:
  - FormActionsTest submit/1 keeps active live form values when conditional fields are removed: 2210ms -> 744ms
  - LiveSelectRegressionTest live select outside forms without option phx-click raises a contract error: 1204ms -> 273ms
  - BrowserExtensionsTest press keyboard semantics: 1762ms regular -> moved to slow
  - LiveCheckboxBehaviorTest label-based nameless checkbox: 4510ms regular -> moved to slow
  - CrossDriverMultiTabUserTest browser variant: 1913ms regular -> moved to slow
- Slow lane notable changes:
  - BrowserActionSettleBehaviorTest browser visit recovers from disconnected live-root timeout when snapshot is available: 3064ms -> 1602ms
  - FormActionsTest action failures include possible candidate hints (browser): 1900ms -> 1415ms
- Remaining dominant slow rows are intentional heavy coverage:
  - LocatorParityTest rich snippet locator corpus ~18.7s
  - slow live/browser contract rows around 1.8s to 3.8s
