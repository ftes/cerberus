---
# cerberus-qa21
title: Compare Cerberus and PhoenixTest error diagnostics
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:26:48Z
updated_at: 2026-03-04T06:29:20Z
---

Review PhoenixTest source and tests for assertion/action failure messaging quality and compare with current Cerberus diagnostics.

## Summary of Changes

- Reviewed PhoenixTest diagnostics implementation and tests in `/tmp/phoenix_test_src_qa21` (notably `lib/phoenix_test/assertions.ex` and `lib/phoenix_test/query.ex`).
- Verified PhoenixTest explicitly reports candidate elements (selector matched but text/value/label mismatch) and tests assert those detailed messages.
- Compared Cerberus diagnostics paths (`lib/cerberus/assertions.ex`, driver assert/action failures, browser action/assertion helpers).
- Confirmed Cerberus currently emphasizes generic reason + inspected `observed` map and does not provide PhoenixTest-style candidate element suggestions in user-facing messages.
