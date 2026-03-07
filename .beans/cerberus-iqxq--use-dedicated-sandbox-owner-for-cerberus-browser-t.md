---
# cerberus-iqxq
title: Use dedicated sandbox owner for Cerberus browser tests
status: todo
type: bug
created_at: 2026-03-07T07:34:49Z
updated_at: 2026-03-07T07:34:49Z
---

## Scope

- [ ] Reproduce browser/live sandbox ownership failures with a focused Cerberus regression.
- [ ] Move browser sandbox ownership to a dedicated owner process instead of relying on the test process lifetime.
- [ ] Generate browser sandbox metadata from that owner and stop it in on_exit with a small shutdown grace window.
- [ ] Verify against targeted Cerberus coverage and the EV2 migrated suite failures that showed DBConnection ownership errors.

## Context

EV2 full migrated Cerberus runs are still showing DBConnection.OwnershipError and owner exited errors in nested LiveView mounts while browser tests continue. This matches the failure shape previously fixed in phoenix_test_playwright PR 95, where Playwright moved to a dedicated sandbox owner process plus delayed shutdown so browser-driven LiveViews could outlive the test process briefly without losing DB ownership.

Expected direction:
- browser tests should not use the test process itself as the effective sandbox owner
- Cerberus browser sandbox metadata should be tied to a separate owner lifecycle
- cleanup should happen in on_exit, likely with a small grace delay for LiveView/browser teardown
