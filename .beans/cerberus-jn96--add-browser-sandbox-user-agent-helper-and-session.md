---
# cerberus-jn96
title: Add browser sandbox user-agent helper and session user_agent option
status: completed
type: feature
priority: normal
created_at: 2026-03-02T19:04:13Z
updated_at: 2026-03-02T19:08:29Z
---

Goal: expose helper to provide Ecto SQL sandbox browser user agent and allow top-level session(:browser, user_agent: ...) option so browser sessions can set UA without nested browser opts.\n\nScope:\n- [x] Add public helper function for browser SQL sandbox user-agent\n- [x] Wire top-level session(:browser, user_agent: ...) through browser config normalization\n- [x] Add tests for helper and top-level option behavior\n- [x] Update docs/examples where browser user_agent options are shown

## Summary of Changes
- Added public helper APIs `Cerberus.sql_sandbox_user_agent/2` and `/1` to generate encoded Phoenix SQL sandbox user-agent metadata without a case-module dependency.
- Added guard/validation for top-level `session(:browser, user_agent: ...)` by extending `Cerberus.Options` session-browser schema and validation.
- Added tests:
  - `test/cerberus/sql_sandbox_user_agent_test.exs` for helper behavior and error handling.
  - `test/cerberus/driver/browser/config_test.exs` coverage that top-level `user_agent` overrides nested browser value.
  - `test/cerberus/timeout_defaults_test.exs` validation failure for invalid top-level `user_agent`.
  - `test/cerberus/sql_sandbox_behavior_test.exs` now uses helper and passes top-level `user_agent` for browser sandbox flow.
- Updated docs/examples in README and getting-started guide to show top-level `user_agent` and SQL sandbox helper usage.
