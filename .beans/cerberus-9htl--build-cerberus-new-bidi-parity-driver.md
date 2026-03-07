---
# cerberus-9htl
title: Build cerberus-new BiDi parity driver
status: completed
type: feature
priority: normal
created_at: 2026-03-07T13:27:58Z
updated_at: 2026-03-07T18:42:11Z
---

Implement Cerberus from scratch in ../cerberus-new as a minimal but usable browser driver for Phoenix parity tests.

- [x] Read the current Cerberus architecture, API surface, and fixture harness
- [x] Scaffold the new Mix project with credo, dialyzer, and baseline test harness
- [x] Implement a simple BiDi browser session with CSS locators, one action, and assert support
- [x] Add Phoenix static/live session handling with page-transition loop semantics
- [x] Cover LiveView-specific behavior including phx-click, forms, and out-of-form inputs
- [x] Run format, targeted tests, and full precommit/test suite in cerberus-new
- [x] Commit the implementation and bean changes in small increments

## Summary of Changes

- Scaffolded cerberus-new as a standalone Mix project with Credo, Dialyzer, and a self-contained Phoenix fixture harness.
- Implemented a minimal but usable BiDi browser driver plus a Phoenix session driver with shared API surface.
- Added parity coverage for static pages, LiveView navigation, phx-click, form submission, and out-of-form controls.
- Verified the implementation with format, targeted parity tests, and the project precommit/test checks.
