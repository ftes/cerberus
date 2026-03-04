---
# cerberus-qpwx
title: Add README diagnostics example from test output
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:40:01Z
updated_at: 2026-03-04T06:41:22Z
---

Add a short README example showing assertion failure output with possible candidate hints, based on actual current test behavior.

- [x] Capture a concise real failure message from test/runtime
- [x] Add README snippet with assertion and representative output
- [x] Run format and targeted docs/tests check

## Summary of Changes

- Captured an actual current assertion message in test env using `session() |> visit("/search") |> submit(text: "Definitely Missing Submit")` and rescued `ExUnit.AssertionError`.
- Added a new `Failure Diagnostics` section to `README.md` with a short assertion snippet and concise output excerpt showing `possible candidates`.
- Ran `mix format` and a focused verification: `mix test test/cerberus/form_actions_test.exs:58`.
