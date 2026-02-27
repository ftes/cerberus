---
# cerberus-yrpa
title: Short timeouts in assert_has/refute_has exceed requested deadline
status: todo
type: bug
priority: normal
created_at: 2026-02-27T21:48:26Z
updated_at: 2026-02-27T22:35:41Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/281

Problem:
assert_has/refute_has timeout granularity is effectively clamped by a fixed polling interval (~100ms), so timeout values below that do not behave as requested.

Repro snippet from upstream:

```elixir
|> assert_has("h1", text: "Some title", timeout: 20)
```

Observed upstream: call still waits at least ~100ms due to interval logic.

Expected Cerberus parity checks:
- timeout < polling interval still honors caller-provided upper bound
- polling cadence and deadline behavior are deterministic and documented

## Todo
- [ ] Add timing-focused tests for short timeout behavior (with flake-resistant bounds)
- [ ] Ensure wait loop uses min(timeout, interval) semantics or equivalent
- [ ] Verify no regression for existing async assertion retries
- [ ] Document timeout granularity guarantees

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).
