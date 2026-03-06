---
# cerberus-7cxr
title: Add fixture password auth flows and tests
status: completed
type: feature
priority: normal
created_at: 2026-03-04T18:42:01Z
updated_at: 2026-03-04T18:49:31Z
---

Add phx.gen.auth-style static and live password authentication fixtures for the test app, then add Cerberus tests covering sign up, log in, and log out flows across phoenix and browser drivers.


- [x] Add fixture auth backend and controller routes for password sign up/log in/log out
- [x] Add LiveView auth pages using phx-trigger-action password flows
- [x] Wire fixture router and test supervisor startup for auth fixtures
- [x] Add Cerberus auth flow tests covering static and live routes
- [x] Run focused tests with random PORT and source .envrc

## Summary of Changes

- Added fixture auth modules: AuthStore, AuthController, AuthHelpers, AuthRegisterLive, AuthLogInLive, and AuthDashboardLive.
- Added static auth routes for register/log in/dashboard and password-based register/log in/log out endpoints.
- Added live auth routes and implemented live register/log in forms that submit via phx-trigger-action to shared password endpoints.
- Added browser-backed tests that validate both static and live sign up, log in, and log out flows end-to-end.
- Updated test startup to include and reset AuthStore in test supervisor.
- Validation:
  - source .envrc && PORT=4xxx mix test test/cerberus/password_auth_flow_test.exs (pass)
  - source .envrc && PORT=4xxx mix test test/cerberus/static_navigation_test.exs (pass)
  - source .envrc && PORT=4xxx mix test test/cerberus/documentation_examples_test.exs (pass)
