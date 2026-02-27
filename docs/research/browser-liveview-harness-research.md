# Cerberus Research: Browser + Live + Static Unified Harness

Date: 2026-02-27
Owner bean: cerberus-4yup
Related beans: cerberus-efry, cerberus-ktki, cerberus-sfku, cerberus-syh3

## Problem Statement
We want a test harness in Elixir that:
- executes the same test flows against static, LiveView, and browser drivers,
- preserves one test API (session-first pipe),
- treats browser execution as an oracle for behavior-level parity,
- uses WebDriver BiDi (no CDP/classic WebDriver dependency in Cerberus API design).

## Key Findings
1. `session -> session` API is the least ambiguous for pipe ergonomics.
2. For initial delivery, vertical slices should ship one operation end-to-end across all drivers.
3. Browser-oracle comparisons should report semantic mismatch categories, not only pass/fail.
4. LiveView signal handling should ultimately be event-driven from diff/redirect streams; slice 1 can remain one-shot.
5. Browser assertions should eventually wait in-browser (observer/raf), but slice 1 can be one-shot for speed of delivery.

## Initial Public API (Slice 1)
```elixir
visit(session, path_or_url, opts \\ [])
click(session, locator, opts \\ [])
assert_has(session, locator, opts \\ [])
refute_has(session, locator, opts \\ [])
```

`locator` accepted in slice 1:
- string text
- regex text
- keyword form: `[text: ...]`

Example:
```elixir
session
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1"], exact: true)
```

## Architecture Snapshot
- `Cerberus.Session` keeps driver + driver_state + current_path.
- `Cerberus.Driver` behavior defines per-driver callbacks.
- `Cerberus.Locator` normalizes user locator input.
- `Cerberus.Query` implements shared text semantics once.
- `Cerberus.Assertions` orchestrates assertion lifecycle.
- `Cerberus.Harness.Case` runs scenarios over a driver matrix.

## Harness Strategy
Single scenario spec, multiple driver executions, normalized result records:

Implementation choice for v0: use regular ExUnit tests with driver tags (for example: `@tag drivers: [:static, :live, :browser]`) plus shared helper functions. A custom DSL is deferred.

```elixir
%{
  driver: :static | :live | :browser,
  op: :assert_has | :refute_has | :click,
  locator: term(),
  opts: keyword(),
  result: :pass | :fail,
  reason: String.t() | nil,
  observed: map()
}
```

## Conformance Report Format (Example)
```text
Scenario: counter increments
  static  : PASS
  live    : FAIL  reason=expected text "Count: 1" not found
  browser : PASS

Mismatch category: live-vs-browser/text-state
Locator: [text: "Count: 1"]
Opts: [exact: true, visible: true, normalize_ws: true]
```

## Risks
- Internal coupling risk when reading LiveViewTest internals for richer signals.
- Browser startup/runtime complexity across engines.
- Semantic drift if text normalization is re-implemented per driver.

## Mitigations
- Keep shared semantics in `Cerberus.Query` only.
- Emit rich `observed` payloads in all drivers for diagnostics.
- Track architecture decisions in ADRs and enforce through conformance tests.
