---
# cerberus-zuu8
title: Move sandbox UA helper to Cerberus.Browser and handle checked-out repos
status: completed
type: task
priority: normal
created_at: 2026-03-06T09:19:49Z
updated_at: 2026-03-06T09:26:26Z
---

Implement Cerberus.Browser.user_agent_for_sandbox with safe handling when SQL sandbox is already checked out (already owner/allowed), migrate calls/docs/tests from Cerberus.sql_sandbox_user_agent, and run targeted sandbox tests during changes.

- [ ] Inspect current sandbox user-agent implementation and all call sites
- [ ] Implement Cerberus.Browser.user_agent_for_sandbox with already-checked-out fallback
- [ ] Remove/migrate old Cerberus.sql_sandbox_user_agent API usage
- [ ] Update docs and tests for new API
- [ ] Run targeted sandbox tests and related test subsets
- [ ] Summarize behavior and compatibility decisions

\nWork log:\n- Moved public sandbox user-agent helper from Cerberus to Cerberus.Browser as user_agent_for_sandbox/1 and /2.\n- Added fallback in Cerberus.Browser when start_owner! hits already owner/allowed so metadata uses current process.\n- Removed old Cerberus.sql_sandbox_user_agent public API and private helper functions from lib/cerberus.ex.\n- Migrated docs in docs/getting-started.md and docs/browser-tests.md to Cerberus.Browser.user_agent_for_sandbox.\n- Migrated sandbox behavior test usage to new helper import.\n- Renamed and updated helper unit tests, adding coverage for already-checked-out repo behavior.\n- Ran mix format and targeted sandbox tests with MIX_ENV=test and random PORT=4xxx values; all green.
