---
# cerberus-ea5f
title: Create API example integration tests (static/live/browser)
status: todo
type: task
created_at: 2026-02-27T07:41:05Z
updated_at: 2026-02-27T07:41:05Z
parent: cerberus-ktki
---

## Scope
Create executable tests that validate the intended user-facing syntax from docs.

## Scenarios
- [ ] static page text presence and absence
- [ ] live view click + text update
- [ ] browser click + text update with same test flow

## Example Under Test
```elixir
session
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1"], exact: true)
```

## Done When
- [ ] One shared spec can run for each driver adapter.
- [ ] Failure messages include locator and normalized options.
