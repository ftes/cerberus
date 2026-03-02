---
# cerberus-8khw
title: Remove open_user API and docs references
status: completed
type: task
priority: normal
created_at: 2026-03-02T08:28:25Z
updated_at: 2026-03-02T08:34:04Z
---

Remove public open_user API, update docs/examples/tests to use explicit new session creation for user isolation, and keep open_tab/session as the supported distinction.

## Summary of Changes

- Removed open_user from public Cerberus API and all driver implementations.
- Updated docs and examples to use new session creation for isolated users and keep open_tab for same-user tabs.
- Updated tests and migration fixture code to stop calling open_user.
- Reworded browser switch_tab cross-user error guidance to point to starting a new browser session.
