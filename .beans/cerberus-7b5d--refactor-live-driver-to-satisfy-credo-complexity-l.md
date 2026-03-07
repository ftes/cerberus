---
# cerberus-7b5d
title: Refactor live driver to satisfy Credo complexity limits in check, uncheck, and form field waiting
status: completed
type: task
priority: normal
created_at: 2026-03-07T05:05:56Z
updated_at: 2026-03-07T05:09:11Z
---

\n- Refactored check/uncheck through a shared toggle_checkbox helper and extracted static checkbox error handling.\n- Flattened wait_for_live_form_field via resolve_live_form_field_actionability and smaller predicates for named vs click-without-name cases.\n

- Widened internal HTML helper specs so Dialyzer matches the actual button maps returned with disabled and related state fields.\n

- Verified with source .envrc && PORT=4713 MIX_ENV=test mix test test/cerberus/actionability_disabled_state_test.exs test/cerberus/live_checkbox_behavior_test.exs test/cerberus/checkbox_array_behavior_test.exs test/cerberus/form_actions_test.exs (44 tests, 0 failures, 1 skipped).\n- Verified with source .envrc && PORT=4781 MIX_ENV=test mix precommit (passed).\n
