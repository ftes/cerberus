---
# cerberus-1ybq
title: Support session(conn) and preserve conn in migration rewrites
status: completed
type: feature
priority: normal
created_at: 2026-03-02T14:10:45Z
updated_at: 2026-03-02T14:13:46Z
---

- [x] Add public session(conn) API that seeds non-browser session from existing Plug.Conn\n- [x] Update migration task bootstrap rewrites to use session(conn) for conn-first visit rewrites\n- [x] Update/add tests for session(conn) API and migration output\n- [x] Run formatter and focused tests

## Summary of Changes
Added public session(conn) support in Cerberus so callers can seed non-browser sessions from an existing Plug.Conn and preserve request/session state.
Updated migration bootstrap rewrites for conn-first PhoenixTest visit forms to seed from the existing conn instead of creating a fresh session().
Adjusted migration task tests to assert conn-seeded rewrites and added a Cerberus API test proving session(conn) preserves session state across visits.
Updated README and getting-started docs with a short session(conn) usage note.
Validated with mix format, direnv exec . mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs, and direnv exec . mix test test/cerberus_test.exs:19.
