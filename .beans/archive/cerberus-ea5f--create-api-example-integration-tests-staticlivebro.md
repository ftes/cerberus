---
# cerberus-ea5f
title: Create API example integration tests (static/live/browser)
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:05Z
updated_at: 2026-02-27T11:04:39Z
parent: cerberus-ktki
---

## Scope
Create executable tests that validate the intended user-facing syntax from docs.

## Scenarios
- [x] static page text presence and absence
- [x] live view click + text update
- [x] browser click + text update with same test flow

## Example Under Test
```elixir
session
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1"], exact: true)
```

## Done When
- [x] One shared spec can run for each driver adapter.
- [x] Failure messages include locator and normalized options.

## Summary of Changes

- Added dedicated API-example integration coverage in `test/core/api_examples_test.exs`.
- Added static scenario covering text presence (`assert_has`) and absence (`refute_has`) with public API flow.
- Added shared live/browser counter scenario using the exact documented flow (`visit -> click -> assert_has`).
- Added failure-shape assertions that verify assertion error messages include locator input and options for reproducible debugging.
- Verified formatting (`mix format`) and non-browser execution path with `mix test test/core/api_examples_test.exs --exclude browser` after sourcing `.envrc` and setting `PORT=4108`.
- Browser-path execution remains user-shell authoritative in this Codex sandbox environment.
