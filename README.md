# Cerberus
![Cerberus hero artwork](docs/hero.png)

Cerberus is an experimental Phoenix test harness with one API across:
- `:auto` (PhoenixTest-style static/live auto-detection and switching),
- `:static` / `:live` (explicit non-browser modes, mainly for focused conformance),
- `:browser` (browser-oracle path).

## Key Difference vs PhoenixTest + PhoenixTest.Playwright

Cerberus integrates browser testing directly into the same driver stack and conformance harness, so browser behavior acts as an HTML-spec oracle for static/live semantics.

Cerberus also uses WebDriver BiDi directly (instead of Playwright), keeping the browser layer slimmer and typically faster to start and run in this architecture.

v0 currently ships a first vertical slice:
- session-first API (`session |> visit |> click/fill_in/upload/submit |> assert_has/refute_has`),
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

Multi-user/multi-tab example:

```elixir
primary =
  session(:browser)
  |> visit("/session/user/alice")

tab2 =
  primary
  |> open_tab()
  |> visit("/session/user")

user2 =
  primary
  |> open_user()
  |> visit("/session/user")
```

Unwrap escape-hatch example:

```elixir
session(:live)
|> visit("/live/redirects")
|> unwrap(fn view ->
  view
  |> Phoenix.LiveViewTest.element("button", "Redirect to Counter")
  |> Phoenix.LiveViewTest.render_click()
end)
|> assert_path("/live/counter")
```

Open browser snapshot example:

```elixir
session(:static)
|> visit("/articles")
|> open_browser()
```

Browser screenshot example:

```elixir
session(:browser)
|> visit("/articles")
|> screenshot("tmp/articles.png")
|> screenshot(full_page: true)
```

Browser-only extensions example:

```elixir
alias Cerberus.Browser

session =
  session(:browser)
  |> visit("/browser/extensions")
  |> Browser.type("hello", selector: "#keyboard-input")
  |> Browser.press("Enter", selector: "#press-input")
  |> Browser.with_dialog(fn session ->
    click(session, button("Open Confirm Dialog"))
  end)

cookie = Browser.cookie(session, "_my_cookie")
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
- `label("...")` (form-field lookup by associated label text for `fill_in`/`upload`; in `assert_has`/`refute_has` it is treated as text matching)
- `css("...")`
- `role(:button, name: "...")` (supported roles in this slice: `:button`, `:link`, `:textbox`, `:searchbox`, `:combobox`)
- `testid("...")` (reserved helper; not yet supported by operations in this slice)
- `fill_in/4` also accepts a plain string/regex as label shorthand; explicit text locators (`text(...)`, `[text: ...]`, `~l"..."`) are reserved for generic text matching.
- `upload/4` follows the same label semantics as `fill_in/4` (plain string/regex shorthand or explicit `label(...)`/`css(...)`).

## Conformance Harness

Use ExUnit tags to select applicable drivers per scenario:
Easy switching between browser and non-browser execution is an essential feature: prefer the standard shared API so most scenarios only vary tags/session mode, and use driver-specific escape hatches (for example `unwrap/2`) only when necessary.

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

The script will:
- use pinned local Chrome for Testing when `--install` is set,
- ensure Chrome and ChromeDriver major + build versions match,
- run a real `POST /session` handshake with `webSocketUrl: true`,
- fail fast if `capabilities.webSocketUrl` is missing.

Dependencies: `curl`, `jq`, `unzip`.

## Notes

- `:auto` uses `Phoenix.LiveViewTest` and `Phoenix.ConnTest` to auto-detect static/live on each interaction.
- `:browser` uses WebDriver BiDi with a shared runtime/connection plus per-test `userContext` isolation.
- `open_user/1` creates isolated user state in all drivers.
- `open_tab/1` creates another tab in the same user state in all drivers:
  browser maps this to a new `browsingContext` in the same `userContext`;
  live/static map this to a recycled `Plug.Conn` so cookies/session are shared.
- `within/3` composes nested scopes (`outer inner`) and restores the previous
  scope after the callback. On live sessions, an ID selector that targets a
  nested child LiveView switches operations to that child for the callback.
- Live-driver `fill_in/4` on live routes triggers `phx-change` when present
  (including `_target` payload semantics) and avoids server updates when no
  `phx-change` binding exists.
- `open_browser/1` is a debug helper that snapshots current page HTML to a temp
  file and opens it via system browser command. For tests, `open_browser/2`
  accepts a callback (`fn path -> ... end`) so callers can inspect snapshots
  without launching a browser.
- `screenshot/1,2` is browser-only. It captures a PNG with WebDriver BiDi
  (`browsingContext.captureScreenshot`) and writes to `:path` (or a temp file by
  default). `full_page: true` captures the full document instead of just the
  viewport.
- `Cerberus.Browser` exposes browser-only helpers for screenshot, keyboard
  (`type`/`press`), drag, dialog capture (`with_dialog`), JS evaluation
  (`evaluate_js`), and cookie inspection/mutation (`cookies`, `cookie`,
  `session_cookie`, `add_cookie`).
- `unwrap/2` mirrors PhoenixTest escape-hatch semantics for static/live:
  static callbacks receive a `Plug.Conn` and must return a `Plug.Conn`;
  live callbacks receive the underlying LiveView and may return render output
  or redirect tuples; Cerberus follows redirects and updates session mode/path.
  Browser mode passes `%{user_context_pid:, tab_id:}` for low-level access.
- Live-driver `click_button` treats `phx-click` raw events and JS `push`/`navigate`/`patch` bindings as actionable. It also supports `JS.dispatch("change")` buttons when they are associated with a form that has `phx-change`. Dispatch-only buttons outside that form context remain non-actionable.
- Fixture LiveView browser bootstrap lives in `assets/js/app.js`; run `mix assets.build` to sync `priv/static/assets/app.js`.
- Browser worker topology and restart semantics are documented in `docs/adr/0004-browser-runtime-supervision-topology.md`.
- Internal deterministic fixture routes are documented in `docs/fixtures.md`.

## Migration Task

Cerberus includes a migration task to help convert PhoenixTest usage:

```bash
mix igniter.cerberus.migrate_phoenix_test
mix igniter.cerberus.migrate_phoenix_test --write test/my_app_web/features
```

Behavior:
- Dry-run by default with `git diff --no-index` preview output.
- Rewrites safe module references (`PhoenixTest` -> `Cerberus`) where deterministic.
- Emits warnings for patterns requiring manual migration (for example `PhoenixTest.Playwright` and `conn |> visit(...)` flows).
