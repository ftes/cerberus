---
# cerberus-0p9l
title: Add Cerberus.unwrap API parity slice
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:47:04Z
updated_at: 2026-02-27T20:13:50Z
parent: cerberus-zqpu
---

## Scope
Add Cerberus.unwrap/2 API parity with PhoenixTest as an escape hatch over native driver values (conn/view/browser handles) with redirect-aware session updates.

## Notes
- Mirror PhoenixTest semantics and error behavior.
- Keep implementation simple and focused on the public API contract.

## Done When
- [x] Cerberus.unwrap/2 is implemented with docs/specs.
- [x] Tests cover success and failure/invalid-input behavior.
- [x] Conformance notes mention parity intent vs PhoenixTest.

## Summary of Changes
- Added Cerberus.unwrap/2 public API with static/live/browser clauses.
- Static unwrap now accepts conn callback return values, updates session state, and follows redirect responses.
- Live unwrap now accepts render outputs and redirect tuples, updates live/static session state, and preserves path transitions.
- Browser unwrap exposes user_context_pid/tab_id callback handles and returns the session.
- Added public API tests covering static/live/browser success paths and invalid callback/result behavior.
- Updated README notes with PhoenixTest parity intent and unwrap semantics.
