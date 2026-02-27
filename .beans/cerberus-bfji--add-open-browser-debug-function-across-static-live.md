---
# cerberus-bfji
title: Add open_browser debug function across static, live, and browser drivers
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:55:35Z
updated_at: 2026-02-27T20:33:15Z
parent: cerberus-zqpu
---

Implement an open_browser helper for dev and debug workflows with consistent API shape across all drivers, following PhoenixTest conventions.

## Scope
- Define shared API contract and return semantics for open_browser
- Implement behavior for static driver
- Implement behavior for live driver
- Implement behavior for browser driver

## Done When
- [x] Public API and docs define open_browser semantics clearly
- [x] Static, live, and browser drivers support open_browser with consistent behavior
- [x] Tests cover cross-driver behavior and error cases
- [x] Harness coverage validates no semantic drift between drivers

## Summary of Changes
- Added Cerberus.open_browser/1 with a doc-false Cerberus.open_browser/2 callback hook for testable debug snapshots.
- Added Cerberus.OpenBrowser utility to write temp HTML snapshots, inject base href for asset resolution, and open snapshots via system command.
- Extended driver contract with open_browser callback and implemented static, live, and browser driver support with consistent callback path semantics.
- Added public API tests for static, live, and browser open_browser behavior plus invalid callback handling.
- Added cross-driver conformance harness coverage in test/core/open_browser_conformance_test.exs for static and live flows against browser.
- Updated README with open_browser usage and semantics notes.
