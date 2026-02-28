---
# cerberus-ktki
title: 'API Shape: Session-First, Locator-as-First-Arg'
status: completed
type: epic
priority: normal
created_at: 2026-02-27T07:40:06Z
updated_at: 2026-02-28T06:42:25Z
parent: cerberus-efry
---

## Objective
Define and lock a clear, ergonomic public API for test authors before deeper implementation.

## Core API Rule
All public operations are `session -> session` and pipe-friendly.
No public "located element" pipeline type in v0.

## Proposed Function Signatures
```elixir
visit(session, path_or_url, opts \\ [])
click(session, locator, opts \\ [])
fill_in(session, locator, opts)                  # opts includes :with
assert_has(session, locator, opts \\ [])
refute_has(session, locator, opts \\ [])
```

`locator` accepted forms in v0:
- `"CSS selector"` (legacy/simple)
- `"text literal"` for text-only assertions where selector is optional
- `%Regex{}` for text assertions
- keyword/map spec (future-compatible): `[text: "Saved"]`, `[role: "button", name: "Save"]`

## Concrete Example Tests (Target UX)
```elixir
defmodule Cerberus.ApiSlice1Test do
  use ExUnit.Case, async: true
  import Cerberus

  test "static: assert text" do
    conn()
    |> visit("/articles")
    |> assert_has([text: "Articles"])
    |> refute_has([text: "500 Internal Server Error"])
  end

  test "live: click then assert" do
    conn()
    |> visit("/live/counter")
    |> click([text: "Increment"])
    |> assert_has([text: "Count: 1"])
  end

  test "browser: same flow" do
    browser_session()
    |> visit("/live/counter")
    |> click([text: "Increment"])
    |> assert_has([text: "Count: 1"])
  end
end
```

## API Semantics for Slice 1
- `assert_has(locator)` succeeds on first matching node for text condition.
- `refute_has(locator)` succeeds when no matching node exists.
- Text matching options in slice 1:
  - `exact: true | false` (default `false`)
  - `normalize_ws: true | false` (default `true`)
  - `visible: true | false | :any` (default `true`)

## Work Breakdown
- [ ] Implement top-level `Cerberus` public module with these function contracts.
- [ ] Ensure all functions return updated session structs.
- [ ] Add API docs with examples for static/live/browser parity.
- [ ] Add compilation tests for all accepted locator input forms.
- [ ] Define and document unsupported options for slice 1 (clear errors, no silent ignore).

## Acceptance Criteria
- [ ] No public API requires a separate `locate(...)` step.
- [ ] Example tests above pass (or have explicit pending tags per slice status).
- [ ] Dialyzer typespecs reflect `session -> session` contract.

## Summary of Changes
- Delivered the session-first public API shape and locator-as-first-arg model across static/live/browser flows.
- Landed locator normalization and ergonomic helpers/sigil support consistent with the v0 surface.
- Added API-level example and conformance coverage to validate the shape across drivers.
- Completed the API parity feature track (cerberus-zqpu) under this epic.
