---
# cerberus-x1qf
title: Fix non-browser session persistence across POST redirects
status: completed
type: bug
priority: normal
created_at: 2026-03-04T18:49:49Z
updated_at: 2026-03-04T18:52:21Z
---

Auth fixture flows revealed that non-browser (phoenix/live) submit redirects lose session state. Diagnose and fix static/live driver redirect handling so put_session survives POST->redirect flows.

## Summary of Changes

- Fixed non-browser POST redirect session persistence by preventing stale cookie request headers from being re-applied after conn recycle in Cerberus.Phoenix.Conn.
- Re-enabled auth flow coverage for both phoenix and browser in password_auth_flow_test.
- Verified auth end-to-end flows now pass for static and live signup/login/logout in non-browser mode as well.

## Verification

- source .envrc && PORT=4193 mix test test/cerberus/password_auth_flow_test.exs (4 tests, 0 failures)
- source .envrc && PORT=4271 mix test test/cerberus/current_path_test.exs test/cerberus/live_link_navigation_test.exs test/cerberus/form_button_ownership_test.exs (24 tests, 0 failures)
