---
# cerberus-ztu3
title: Fix slow test include compile failure
status: completed
type: bug
priority: normal
created_at: 2026-03-04T18:37:24Z
updated_at: 2026-03-04T18:46:46Z
---

Reproduce and fix the failure when running MIX_ENV=test mix test --include slow, currently crashing with MatchError {:error, :enoent} during test compilation. Add/adjust coverage if needed and verify slow suite runs.

## Summary of Changes
- Fixed slow migration tests to avoid global CWD sensitivity by using absolute project and fixture paths in test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs.
- Updated migration subprocess env so CERBERUS_PATH is deterministic from module-level project root instead of process CWD.
- Serialized test/mix/tasks/cerberus_install_tasks_test.exs (async false) because it intentionally changes CWD, preventing cross-test interference.
- Extended migration canonicalization to wrap bare locator variables for form-field operations (fill_in, select, choose, check, uncheck, upload) as label(variable), fixing post-migration failures like choose(session, label_var).
- Added regression coverage for the variable-locator rewrite and refreshed expectations for current canonicalized assert_has output.
- Verified these commands pass: source .envrc && PORT=4812 MIX_ENV=test mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs --include slow, and source .envrc && PORT=4964 MIX_ENV=test mix test --only slow.
