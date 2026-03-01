---
# cerberus-3b1u
title: Internalize or remove public helper seams session_for_driver and driver_module
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T17:32:35Z
---

Finding follow-up: hidden helper functions in Cerberus are still publicly callable and used by harness internals.

## Scope
- Remove/relocate public helper API seams not intended for end users
- Update harness internals to avoid reliance on public helper exposure
- Preserve test behavior and failure messages

## Acceptance
- Helpers are no longer accidental public API

## Summary of Changes
- Removed public helper seams Cerberus.session_for_driver/2 and Cerberus.driver_module!/1 from the public root module.
- Internalized driver dispatch in Cerberus and Cerberus.Assertions via private per-session dispatch helpers.
- Updated harness internals to create sessions and validate driver kinds without calling public helper seams.
- Updated tests that depended on the public seam to use public constructors and per-session driver submit dispatch.
- Ran mix format and mix precommit; precommit passed. Focused mix test runs still hit the known sqlite disk I/O lock issue from test/test_helper.exs.
