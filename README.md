# Cerberus

Cerberus is an experimental Phoenix test harness with one API across:
- `:auto` (PhoenixTest-style static/live auto-detection and switching),
- `:static` / `:live` (explicit non-browser modes, mainly for focused conformance),
- `:browser` (browser-oracle path).

v0 currently ships a first vertical slice:
- session-first API (`session |> visit |> click |> assert_has/refute_has`),
- text locators (`"text"`, `~r/regex/`, `[text: ...]`),
- one-shot assertions with deterministic fixture-backed adapters.

## API Example

```elixir
import Cerberus

session(:auto)
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
  @tag drivers: [:auto, :browser]
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

## Browser Binary Config

Test runs require these env vars:
- `CHROME`
- `CHROMEDRIVER`

Optional browser visibility env var:
- `SHOW_BROWSER` (`true`/`1`/`yes`/`on` to run headed; default is `false`)

`config/test.exs` reads `CHROME` and `CHROMEDRIVER` with `System.fetch_env!/1`,
and maps `SHOW_BROWSER=true` to `config :cerberus, :browser, show_browser: true`.
There is no PATH/default fallback for browser binaries.

The repository `.envrc` is pinned to a local Chrome for Testing runtime under
`tmp/browser-tools` (default pinned version: `145.0.7632.117`). No system Chrome
path is used in default project wiring.

Load env vars before running browser tests:

```bash
direnv allow
```

## WebDriver BiDi Readiness

Use the built-in check script to install and validate local runtime setup:

```bash
bin/check_bidi_ready.sh --install
```

The script will install pinned Chrome + matching ChromeDriver into
`tmp/browser-tools`, validate version/build parity, and run a real WebDriver
session handshake with `webSocketUrl: true`.

After install, it writes `tmp/browser-tools/env.sh` with:
- `CHROME`
- `CHROMEDRIVER`
- `CERBERUS_CHROME_VERSION`

The script will:
- use pinned local Chrome for Testing when `--install` is set,
- ensure Chrome and ChromeDriver major + build versions match,
- run a real `POST /session` handshake with `webSocketUrl: true`,
- fail fast if `capabilities.webSocketUrl` is missing.

Dependencies: `curl`, `jq`, `unzip`.

## Notes

- `:auto` uses `Phoenix.LiveViewTest` and `Phoenix.ConnTest` to auto-detect static/live on each interaction.
- `:browser` uses WebDriver BiDi with a shared runtime/connection plus per-test `userContext` isolation.
- Fixture LiveView browser bootstrap lives in `assets/js/app.js`; run `mix assets.build` to sync `priv/static/assets/app.js`.
- Browser worker topology and restart semantics are documented in `docs/adr/0004-browser-runtime-supervision-topology.md`.
- Internal deterministic fixture routes are documented in `docs/fixtures.md`.
