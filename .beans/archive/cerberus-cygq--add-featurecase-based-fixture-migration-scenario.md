---
# cerberus-cygq
title: Add FeatureCase-based fixture migration scenario
status: completed
type: task
priority: normal
created_at: 2026-03-02T14:20:15Z
updated_at: 2026-03-02T14:28:26Z
---

- [x] Add migration fixture FeatureCase that imports PhoenixTest in using\n- [x] Add pt_* feature test that uses FeatureCase without importing PhoenixTest\n- [x] Ensure migration verification rewrites support files needed by this scenario\n- [x] Run focused migration task tests

## Summary of Changes

- Added fixture support module at fixtures/migration_project/test/support/feature_case.ex that imports PhoenixTest via FeatureCase using.
- Added fixture test at fixtures/migration_project/test/features/pt_feature_case_import_test.exs using FeatureCase without direct PhoenixTest import.
- Fixed fixture route usage to /search so pre-migration PhoenixTest tests run successfully.
- Fixed migration import insertion to handle Sourceror do-block keys and insert import Cerberus in rewritten local-call modules.
- Expanded migration test coverage to verify support file rewriting when running migration on test root.
- Ran focused migration tests: direnv exec . mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs.
