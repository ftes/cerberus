# Cerberus
[![Hex.pm Version](https://img.shields.io/hexpm/v/cerberus)](https://hex.pm/packages/cerberus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cerberus/)
[![License](https://img.shields.io/hexpm/l/cerberus.svg)](https://github.com/ftes/cerberus/blob/main/LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ftes/cerberus/ci.yml)](https://github.com/ftes/cerberus/actions)
![Cerberus hero artwork](docs/hero.png)

Cerberus is an experimental Phoenix testing harness with one API across:
- non-browser Phoenix mode (`session()` / `session(:phoenix)`, with static/live auto-detection and switching),
- browser mode (`session(:browser)` defaulting to Chrome, plus `session(:chrome)` / `session(:firefox)`), WebDriver BiDi browser-oracle execution.

Cerberus is designed for teams that want to write one feature-test flow and run it in browser and non-browser modes with minimal rewrites.

## 30-Second Start
```ex
# mix.exs
{:cerberus, "~> 0.1"}
```

```elixir
import Cerberus

session()
|> visit("/live/counter")
|> click(button("Increment"))
|> assert_has(text("Count: 1"))
```

> #### Tip
>
> Start with `session()` for most scenarios. Move to `session(:browser)` when validating real browser behavior, keyboard/mouse APIs, or browser-only assertions.
> Use `session(:chrome)` / `session(:firefox)` when you want an explicit browser target.

## Progressive Examples

### 1. Static Text Assertions

```elixir
session()
|> visit("/articles")
|> assert_has(text("Articles"))
|> refute_has(text("500 Internal Server Error"))
```

### 2. LiveView Interaction

```elixir
session()
|> visit("/live/counter")
|> click(role(:button, name: "Increment"))
|> assert_has(text("Count: 1"))
```

### 3. Form + Path Assertions

```elixir
session()
|> visit("/search")
|> fill_in(label("Search term"), "Aragorn")
|> submit(button("Run Search"))
|> assert_path("/search/results", query: %{q: "Aragorn"})
|> assert_has(text("Search query: Aragorn"))
```

### 4. Scope + Navigation

```elixir
session()
|> visit("/scoped")
|> within("#secondary-panel", fn scoped ->
  scoped
  |> assert_has(text("Status: secondary"))
  |> click(link("Open"))
end)
|> assert_path("/search")
```

### 5. Multi-User + Multi-Tab

```elixir
primary =
  session()
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

### 6. Browser-Only Extensions

```elixir
alias Cerberus.Browser

session =
  session(:browser)
  |> visit("/browser/extensions")
  |> Browser.type("hello", selector: "#keyboard-input")
  |> Browser.press("Enter", selector: "#press-input")
  |> Browser.with_dialog(fn dialog_session ->
    click(dialog_session, button("Open Confirm Dialog"))
  end)

session
|> assert_has(text("Press result: submitted"))
|> assert_has(text("Dialog result: cancelled"))
```

> #### Warning
>
> `Cerberus.Browser.*` helpers are intentionally browser-only. Calling them on non-browser sessions raises explicit unsupported-operation assertions.

## Locator Quick Look

- Helper constructors:
  - `text("...")`, `link("...")`, `button("...")`, `label("...")`, `css("...")`, `role(:button, name: "...")`
- Sigil:
  - `~l"text"` (text locator)
  - modifiers:
    - `e` / `i` exact/inexact default
    - `r` role form (`~l"button:Save"r`)
    - `c` CSS form (`~l"button[type='submit']"c`)

## Switching Modes

Most tests switch modes by changing only the first session line:

```diff
-session()
+session(:browser)
 |> visit("/live/counter")
 |> click(button("Increment"))
 |> assert_has(text("Count: 1"))
```

## Per-Test Browser Overrides

You can override browser defaults in one test by passing session opts:

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  browser: [viewport: {390, 844}, user_agent: "Cerberus Mobile Spec"]
)
|> visit("/live/counter")
```

Isolation strategy:
- runtime process + BiDi transport stay shared,
- each `session(:browser, ...)` creates an isolated browser user context,
- context-level overrides (viewport/user-agent/init scripts) are isolated per session and do not require a dedicated browser process.

## Timeout Defaults

You can configure default assertion and browser readiness timeouts once:

```elixir
config :cerberus, :assert_timeout_ms, 300

config :cerberus, :browser,
  ready_timeout_ms: 2_200,
  bidi_command_timeout_ms: 5_000,
  runtime_http_timeout_ms: 9_000,
  dialog_timeout_ms: 1_500,
  screenshot_full_page: false,
  screenshot_artifact_dir: "tmp/cerberus-artifacts/screenshots"
```

Override precedence is:
- call opts (`assert_has(..., timeout: ...)`)
- session opts (`session(assert_timeout_ms: ...)`, `session(:browser, ready_timeout_ms: ...)`)
- app config
- hardcoded fallback

`bidi_command_timeout_ms` is used as the default timeout for WebDriver BiDi commands.
`runtime_http_timeout_ms` is used for browser runtime HTTP calls (for example WebDriver `/status` and session lifecycle requests).
`dialog_timeout_ms` is used by `Browser.with_dialog/3` when a call-level `timeout:` is not provided.
`screenshot_full_page` is the default for `screenshot(..., full_page: ...)` when the call omits `full_page`.
`screenshot_artifact_dir` controls where generated screenshot files are written when no `path:` is provided.
You can optionally set `screenshot_path` in `:cerberus, :browser` to force a single default output path.
Per-command `timeout:` still takes precedence when provided.

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)
- [Browser Support Policy](docs/browser-support-policy.md)
- [Migration Verification Matrix](docs/migration-verification-matrix.md)

## Browser Runtime Setup

Cerberus browser tests use WebDriver BiDi.
Current Tier 1 support is Chrome/Chromium via ChromeDriver; see the Browser Support Policy for broader target status.

Local managed runtime (default) requires:
- `CHROME`
- `CHROMEDRIVER`
- `FIREFOX` (for `session(:firefox)` / Firefox matrix runs)
- `GECKODRIVER` (for `session(:firefox)` / Firefox matrix runs)

Optional:
- `SHOW_BROWSER=true` to run headed.

Remote runtime mode:

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

With `webdriver_url` set, Cerberus does not launch local Chrome/ChromeDriver and does not require `CHROME`/`CHROMEDRIVER` for runtime startup.

Cross-browser matrix (harness expansion):

```bash
CERBERUS_BROWSER_MATRIX=chrome,firefox mix test --only browser
```

`CERBERUS_BROWSER_MATRIX` defaults to `browser` (single default browser lane).

Project helpers:

```bash
bin/check_browser_bidi_ready.sh chrome --install
bin/check_browser_bidi_ready.sh firefox --install
```

These helpers install browser/runtime binaries under `tmp/browser-tools`, write `tmp/browser-tools/env.sh`, and verify `webSocketUrl` BiDi handshake support.

Direct browser-specific entrypoints:

```bash
bin/check_chrome_bidi_ready.sh --install
bin/check_firefox_bidi_ready.sh --install
```

## Migration Task

Cerberus includes an Igniter migration task for PhoenixTest codebases:

```bash
mix igniter.cerberus.migrate_phoenix_test
mix igniter.cerberus.migrate_phoenix_test --write test/my_app_web/features
```

It performs safe rewrites, reports manual follow-ups, and defaults to dry-run diff output.

Migration verification runner:

```bash
mix cerberus.verify_migration
mix cerberus.verify_migration --keep --work-dir tmp/migration_verify
```

This runs a pre-migration fixture test, applies the rewrite, then runs the post-migration fixture test in an isolated copied workspace.
