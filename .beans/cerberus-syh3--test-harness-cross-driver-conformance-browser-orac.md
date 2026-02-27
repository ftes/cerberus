---
# cerberus-syh3
title: 'Test Harness: Cross-Driver Conformance + Browser Oracle'
status: todo
type: epic
priority: normal
created_at: 2026-02-27T07:40:42Z
updated_at: 2026-02-27T07:56:20Z
parent: cerberus-efry
---

## Objective
Create a harness that runs one spec against static/live/browser and compares normalized outcomes.
Easy switching between browser and non-browser (`:auto`/`:static`/`:live`) execution is an essential feature. Prefer the standard shared API so scenarios switch cleanly, while allowing targeted driver-specific escape hatches (for example, `unwrap/2`) when needed.

## Harness Design
- Regular ExUnit tests + shared helpers define the shared spec contract in v0.
- Driver matrix generated at compile time:
  - `:static`
  - `:live`
  - `:browser`
- Each scenario runs per driver with same fixture route and same API calls.

## Output Model
Normalize each assertion result into:
```elixir
%{
  driver: atom(),
  op: :assert_has | :refute_has | :click,
  locator: term(),
  opts: keyword(),
  result: :pass | :fail,
  reason: String.t() | nil,
  observed: map()
}
```

## Oracle Mode
- Browser outcome is the reference for browser behavior.
- Compare static/live to browser for selected specs.
- Mismatch report includes:
  - operation + locator + opts
  - static/live observed
  - browser observed
  - suggested semantic gap label (visibility, whitespace, count, path, etc)

## Example Harness Spec (v0)
```elixir
defmodule Cerberus.Conformance.TextPresenceTest do
  use ExUnit.Case, async: false
  import Cerberus

  @tag drivers: [:static, :live, :browser]
  test "counter increments", %{session: session} do
    session
    |> visit("/live/counter")
    |> click([text: "Increment"])
    |> assert_has([text: "Count: 1"], exact: true)
  end
end
```

## Work Breakdown
- [ ] Build ExUnit helper utilities and driver-tag conventions for matrix execution.
- [ ] Build fixture app routes/pages for deterministic static + live + browser tests.
- [ ] Add normalized result struct and reporter.
- [ ] Add `--oracle browser` comparison mode.
- [ ] Add at least 10 conformance cases for text assertions.
- [ ] Add one intentional mismatch fixture to validate diff reporting quality.

## Acceptance Criteria
- [ ] Same scenario file runs across all 3 drivers.
- [ ] Most switching between browser and non-browser execution is done by changing driver tags/session mode; when driver-specific behavior is required (for example `unwrap/2`), keep it isolated and minimal.
- [ ] Reporter prints grouped mismatches by semantic category.
- [ ] CI can run `conformance` suite independently from unit tests.

## Implementation Note (v0)
Use regular ExUnit tests with driver tags (`@tag drivers: [:static, :live, :browser]`) and shared helper functions.
A custom harness DSL is optional future work, not a requirement for slice 1.
