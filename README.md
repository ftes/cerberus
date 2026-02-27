# Cerberus

Cerberus is an experimental Phoenix test harness with one API across:
- `:static` (stateless HTML),
- `:live` (LiveView semantics),
- `:browser` (browser-oracle path).

v0 currently ships a first vertical slice:
- session-first API (`session |> visit |> click |> assert_has/refute_has`),
- text locators (`"text"`, `~r/regex/`, `[text: ...]`),
- one-shot assertions with deterministic fixture-backed adapters.

## API Example

```elixir
import Cerberus

session(:live)
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1"], exact: true)
```

## Conformance Harness

Use ExUnit tags to select applicable drivers per scenario:

```elixir
defmodule MyConformanceTest do
  use ExUnit.Case, async: true
  import Cerberus

  alias Cerberus.Harness

  @tag :conformance
  @tag drivers: [:static, :live, :browser]
  test "shared behavior", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/articles")
      |> assert_has([text: "Articles"])
    end)
  end
end
```

Run conformance tests only:

```bash
mix test --only conformance
```

Core integration specs live in `test/core/`.

## WebDriver BiDi Readiness

Use the built-in check script to validate local browser runtime setup:

```bash
bin/check_bidi_ready.sh --install
```

The script will:
- detect your Chrome binary/version,
- ensure ChromeDriver major version matches (and download a matching driver when `--install` is set),
- run a real `POST /session` handshake with `webSocketUrl: true`,
- fail fast if `capabilities.webSocketUrl` is missing.

Dependencies: `curl`, `jq`, `unzip`.

## Notes

- `:live` now uses `Phoenix.LiveViewTest` against the fixture Phoenix app.
- `:browser` uses WebDriver BiDi with a shared runtime/connection plus per-test `userContext` isolation.
- Fixture LiveView browser bootstrap lives in `assets/js/app.js`; run `mix assets.build` to sync `priv/static/assets/app.js`.
- Browser worker topology and restart semantics are documented in `docs/adr/0004-browser-runtime-supervision-topology.md`.
- Internal deterministic fixture routes are documented in `docs/fixtures.md`.
