---
# cerberus-bflg
title: Global default for browser dialog timeout
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:11:06Z
updated_at: 2026-02-28T08:12:22Z
---

Add a global default for Browser.with_dialog timeout while preserving per-call overrides.

## Summary of Changes

- Added global browser dialog timeout resolution for Browser.with_dialog/3 (`dialog_timeout_ms`) in `Cerberus.Driver.Browser.Extensions`.
- Preserved per-call override precedence: `timeout:` still wins over configured defaults.
- Added timeout default conformance test coverage in `test/cerberus/timeout_defaults_test.exs`.
- Documented `dialog_timeout_ms` in README Timeout Defaults section.
