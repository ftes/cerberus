---
# cerberus-iyju
title: Tighten Playwright-style locator parity for accessible names and roles
status: todo
type: epic
created_at: 2026-03-08T08:50:15Z
updated_at: 2026-03-08T08:50:15Z
---

## Context

The aria-label cut aligned the public API with Playwright in spirit, but locator behavior is still only a bounded approximation. Follow-up work should tighten accessible-name semantics, broaden supported roles, remove older assertion routing leftovers, and expand cross-driver parity coverage.

## Child Slices

- Fuller accessible-name semantics for role locators
- Broader supported role coverage
- Internal assertion cleanup after public match_by removal
- Mixed naming-source parity fixtures and assertions across browser, static, and live
- Larger oracle coverage for aria-labelledby and accessible-name cases

## Exit Criteria

- Role locators behave closer to Playwright for supported roles
- Role support covers the next practical set of common ARIA and landmark roles
- Assertions are driven by locators internally rather than generic match_by-style routing
- Browser, static, and live drivers share stronger parity coverage for accessible-name edge cases
