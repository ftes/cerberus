---
# cerberus-9xmc
title: Move SQL sandbox setup to fully vanilla Phoenix.Ecto pattern
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:14:56Z
updated_at: 2026-03-03T19:27:13Z
---

Replace custom owner reuse/reset logic in Cerberus.sql_sandbox_user_agent with direct start_owner!/metadata_for/encode_metadata and on_exit stop_owner semantics from Phoenix.Ecto docs; validate sandbox behavior tests and stress loop.

## Progress
- Replaced custom sandbox owner reuse/reset logic in lib/cerberus.ex with vanilla Phoenix.Ecto flow: start_owner! per call, metadata_for, encode_metadata, and on_exit stop_owner.
- Removed process dictionary tracking and 'Ecto not loaded' fallback from sql_sandbox_user_agent path.
- Validation: mix test test/cerberus/sql_sandbox_user_agent_test.exs test/cerberus/sql_sandbox_behavior_test.exs passed.
- Stress validation (live/browser case): VANILLA_STRESS runs=50 fails=0 ownership_failures=0 chrome_start_failures=0 addr_in_use_failures=0.

## Summary of Changes
- Replaced custom SQL sandbox owner reuse/reset logic with vanilla Phoenix.Ecto flow in Cerberus.sql_sandbox_user_agent.
- Now always uses Ecto.Adapters.SQL.Sandbox.start_owner!/2 + Phoenix.Ecto.SQL.Sandbox.metadata_for/2 + encode_metadata/1 and on_exit stop_owner.
- Validated with targeted sandbox tests and stress loops without ownership failures.
