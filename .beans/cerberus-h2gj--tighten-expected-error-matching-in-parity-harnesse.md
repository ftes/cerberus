---
# cerberus-h2gj
title: Tighten expected-error matching in parity harnesses
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:25:23Z
updated_at: 2026-03-06T10:27:41Z
---

## Goal
Make parity tests fail loudly on unexpected error types/messages instead of only status-level matching.

## Todo
- [x] Audit test harnesses that capture errors as status tuples
- [x] Tighten locator_parity expected-error assertions
- [x] Apply same strictness to similar modules where appropriate
- [x] Run targeted tests with envrc and random PORT

## Summary of Changes
- Audited test modules for status-based error capture and found this pattern only in `test/cerberus/locator_parity_test.exs`.
- Tightened parity harness assertions so every `expect: :error` case must provide `error_module`, and every `expect: :ok` case must not provide error metadata.
- Added optional `error_contains` support and used it for the selector-removal case to assert the error message contains `unknown options [:selector]`.
- Kept rescue scope narrow (`AssertionError`, `ArgumentError`, `InvalidLocatorError`) so unexpected exceptions still fail the test directly.
- Ran `mix format test/cerberus/locator_parity_test.exs` and validated with `source .envrc && PORT=4182 mix test test/cerberus/locator_parity_test.exs --include slow` (2 tests, 0 failures).
