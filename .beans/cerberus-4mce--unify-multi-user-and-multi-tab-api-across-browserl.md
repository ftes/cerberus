---
# cerberus-4mce
title: Unify multi-user and multi-tab API across browser/live/static drivers
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:43:01Z
updated_at: 2026-02-27T20:01:31Z
parent: cerberus-sfku
---

## Scope
Design and implement a single public Cerberus API for multi-user and multi-tab workflows that can run unchanged across browser and live/static drivers.

## Goals
- Introduce a common user+tab session model in public API.
- Map browser behavior to userContext+browsingContext.
- Map live/static behavior to shared cookie/session jar per user and per-tab session instances.
- Keep tests mode-switchable between browser and live/static.

## Done When
- [x] Public API exists for opening/switching/closing users and tabs.
- [x] Browser driver implements the API with tab semantics.
- [x] Live/static drivers implement compatible semantics.
- [x] Cross-driver conformance tests validate same scenario in browser and live/static.
- [x] Docs explain semantic differences (cookies/storage/events).

## Summary of Changes
- Added public multi-session API in Cerberus: open_user/1, open_tab/1, switch_tab/2, close_tab/1.
- Extended browser session model with explicit tab_id and routed browser operations through tab-targeted UserContextProcess calls for deterministic per-tab execution.
- Implemented live/static compatibility semantics using conn forking (open_tab shares cookies/session via recycled conn; open_user isolates user state via fresh conn with preserved headers).
- Added deterministic fixture routes /session/user and /session/user/:value for cookie/session conformance.
- Added cross-driver conformance coverage for multi-tab sharing + multi-user isolation and updated browser tab workflow tests to use public API.
- Updated docs (README.md, docs/fixtures.md) with multi-user/multi-tab semantics and fixture surface.

## Work Log
- Primed beans and resumed cerberus-4mce.
- Implemented API + driver plumbing.
- Added fixture support + tests.
- Ran targeted tests for public API and conformance slices.
- Ran mix precommit; it still fails due existing repository-wide Dialyzer baseline warnings unrelated to this slice.
