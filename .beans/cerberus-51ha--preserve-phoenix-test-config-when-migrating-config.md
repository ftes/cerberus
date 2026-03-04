---
# cerberus-51ha
title: Preserve phoenix_test config when migrating config/test.exs
status: completed
type: bug
priority: normal
created_at: 2026-03-04T18:07:27Z
updated_at: 2026-03-04T18:11:55Z
---

Fix cerberus.migrate_phoenix_test so config/test.exs keeps existing config :phoenix_test entries and only adds config :cerberus entries. Do not swap app key from phoenix_test to cerberus.


## Todo

- [x] Remove config app swapping from migration AST rewrite
- [x] Add post-pass to ensure `config :cerberus, endpoint: ...` exists in config/test.exs
- [x] Keep existing `config :phoenix_test` entries unchanged
- [x] Update migration task tests for new config behavior
- [x] Run targeted migration-task test suite

## Summary of Changes

- Removed the migration rewrite that changed `config :phoenix_test` to `config :cerberus`.
- Added `maybe_ensure_cerberus_endpoint_config/2`, which appends `config :cerberus, endpoint: ...` only when missing.
- Preserved existing `:phoenix_test` config blocks entirely (including options like `otp_app`/`playwright`).
- Updated test coverage to assert PhoenixTest config remains and Cerberus endpoint config is added.
- Verified with `source .envrc && PORT=4984 mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs` (pass).
