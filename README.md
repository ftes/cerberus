# Cerberus

Cerberus is an experimental Phoenix test harness with one API across:
- `:auto` (PhoenixTest-style static/live auto-detection and switching),
- `:static` / `:live` (explicit non-browser modes, mainly for focused conformance),
- `:browser` (browser-oracle path).

v0 currently ships a first vertical slice:
- session-first API (`session |> visit |> click |> assert_has/refute_has`),
- text locators (`"text"`, `~r/regex/`, `[text: ...]`),
- deterministic fixture-backed adapters with optional timeout-aware live assertions,
- path assertions (`assert_path` / `refute_path`) and scoped flows via `within/3`.

## API Example

```elixir
import Cerberus

session(:auto)
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1"], exact: true)
```

Sigil locator examples:

```elixir
session(:static)
|> visit("/articles")
|> assert_has(~l"Articles")
|> assert_has(~l"This is an articles index page"e)
|> refute_has(~l"500 Internal Server Error")
|> click(~l"link:Counter"r)
|> assert_has(~l"button:Increment"re)
```

Helper locator flow:

```elixir
session(:live)
|> visit("/live/counter")
|> click(role(:button, name: "Increment"))
|> assert_has(text("Count: 1"), exact: true)
```

Timeout-aware live assertions:

```elixir
session(:live)
|> visit("/live/async_page")
|> assert_has(text("Title loaded async"), timeout: 350)
```

Path and scoped flow example:

```elixir
session(:auto)
|> visit("/scoped")
|> within("#secondary-panel", fn scoped ->
  scoped
  |> assert_has(text("Status: secondary"), exact: true)
  |> click(link("Open"))
end)
|> assert_path("/search")
```

Supported sigil:
- `~l` for text locators.
- `~l` modifiers:
  - `e` / `i` for exact/inexact text matching defaults.
  - `r` for role-style locators using `ROLE:NAME` text (for example `~l"button:Save"r`, `~l"textbox:Search term"r`).
  - `c` for CSS selector locators (for example `~l"#search_q"c`, `~l"button[type='submit']"c`).

Helper locator constructors:
- `text("...")`
- `link("...")`
- `button("...")`
- `label("...")` (explicit form-field lookup by associated label text; this is distinct from generic text matching)
- `css("...")`
- `role(:button, name: "...")` (supported roles in this slice: `:button`, `:link`, `:textbox`, `:searchbox`, `:combobox`)
- `testid("...")` (reserved helper; not yet supported by operations in this slice)

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

## SQL Sandbox Conformance

Cerberus test harness supports Ecto SQL sandbox setup for conformance scenarios:

```elixir
Harness.run!(context, fn session ->
  # DB setup + assertions
  session |> visit("/sandbox/messages")
end, sandbox: true)
```

When `sandbox: true` is set:
- Harness starts/stops an owner via `Ecto.Adapters.SQL.Sandbox.start_owner!/2`.
- Harness injects encoded metadata into non-browser seeded `conn` user-agent headers.
- Browser driver applies the same metadata as per-session user-agent override.

Fixture LiveViews also read `:user_agent` connect info and call
`Phoenix.Ecto.SQL.Sandbox.allow/2` on mount, matching Phoenix/Ecto guidance for
LiveView processes.

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
- Live-driver `click_button` treats `phx-click` raw events and JS `push`/`navigate`/`patch` bindings as actionable; `dispatch`-only bindings are intentionally excluded from server-actionable resolution.
- Fixture LiveView browser bootstrap lives in `assets/js/app.js`; run `mix assets.build` to sync `priv/static/assets/app.js`.
- Browser worker topology and restart semantics are documented in `docs/adr/0004-browser-runtime-supervision-topology.md`.
- Internal deterministic fixture routes are documented in `docs/fixtures.md`.
