---
# cerberus-inax
title: Investigate full mix test startup sqlite disk I/O failure
status: completed
type: bug
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-02-28T18:14:28Z
---

Missing-tests follow-up: full suite run failed in test setup with Exqlite disk I/O errors.

## Scope
- Reproduce reliably in CI/local where applicable
- Determine whether issue is environment-only or repo configuration bug
- Document mitigation or fix

## Acceptance
- Full-suite startup reliability is understood and actionable

## Summary of Changes

- Reproduced startup instability under overlapping local `mix test` runs and confirmed resource collisions (`sqlite` lock contention and fixed endpoint port collisions).
- Mitigated collisions in `config/test.exs` by deriving per-process test instance defaults (OS PID-based) for both sqlite path (`tmp/cerberus_test_<instance>.sqlite3`) and endpoint port (`4002 + hash(instance) mod 1000`).
- Preserved operator overrides via existing env vars (`PORT`) and new stable instance override (`CERBERUS_TEST_INSTANCE`).
- Verified with concurrent `mix test` invocations that prior lock/port startup errors no longer reproduced in this environment.
