# Cerberus
[![Hex.pm Version](https://img.shields.io/hexpm/v/cerberus)](https://hex.pm/packages/cerberus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cerberus/)
[![License](https://img.shields.io/hexpm/l/cerberus.svg)](https://github.com/ftes/cerberus/blob/main/LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ftes/cerberus/ci.yml)](https://github.com/ftes/cerberus/actions)
![Cerberus hero artwork](docs/hero.png)

Cerberus is an experimental Phoenix testing harness with one API across:
- non-browser Phoenix mode with static/live auto-detection and switching,
- browser mode for Chrome and Firefox via WebDriver BiDi.

Minimal API: You control your tests. Easily run single tests/describe blocks/entire modules in one or more browsers.

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

## Browser Defaults and Runtime Options

You can configure defaults once:

```elixir
config :cerberus, :assert_timeout_ms, 300

config :cerberus, :browser,
  ready_timeout_ms: 2_200,
  ready_quiet_ms: 40,
  bidi_command_timeout_ms: 5_000,
  runtime_http_timeout_ms: 9_000,
  dialog_timeout_ms: 1_500,
  screenshot_full_page: false,
  screenshot_artifact_dir: "tmp/cerberus-artifacts/screenshots",
  show_browser: false
```

Override precedence is:
- call opts (`assert_has(..., timeout: ...)`)
- session opts (`session(assert_timeout_ms: ...)`, `session(:browser, ready_timeout_ms: ...)`, `session(:browser, ready_quiet_ms: ...)`, context overrides in `session(:browser, browser: [...])`)
- app config
- hardcoded fallback

Option scopes:
- Per-session context options: `ready_timeout_ms`, `ready_quiet_ms`, `browser: [viewport: ..., user_agent: ..., init_script: ... | init_scripts: [...]]`.
- Global runtime launch options: `browser_name`, `webdriver_url`, `show_browser`, `headless`, `chrome_args`, `firefox_args`, `chrome_binary`, `firefox_binary`, `chromedriver_binary`, `geckodriver_binary`.
- Global browser defaults: `bidi_command_timeout_ms`, `runtime_http_timeout_ms`, `dialog_timeout_ms`, `screenshot_full_page`, `screenshot_artifact_dir`, `screenshot_path`.

`show_browser: true` runs headed by default. `headless` has higher precedence if both are set.

Because browser runtime + BiDi transport are shared, runtime launch options are fixed when the runtime starts and should be treated as invocation-level config (not per-test toggles).

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)
- [Browser Support Policy](docs/browser-support-policy.md)

## Browser Runtime Setup

Cerberus browser tests use WebDriver BiDi.
Chrome and Firefox are supported browser targets.

Local managed runtime (default) uses configured browser and WebDriver binaries:

```elixir
config :cerberus, :browser,
  chrome_binary: "/path/to/chrome-or-chromium",
  chromedriver_binary: "/path/to/chromedriver",
  firefox_binary: "/path/to/firefox",
  geckodriver_binary: "/path/to/geckodriver"
```

Only the selected browser lane needs to be configured for a given run.

Headed mode:

```elixir
config :cerberus, :browser, show_browser: true
```

Remote runtime mode:

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

With `webdriver_url` set, Cerberus does not launch local browser/WebDriver processes.

Remote `webdriver_url` integration smoke test (Docker required):

```bash
CERBERUS_REMOTE_WEBDRIVER=1 mix test test/core/remote_webdriver_behavior_test.exs
```

This test starts a `selenium/standalone-chromium` container with `docker run`,
connects Cerberus through `webdriver_url`, and force-removes the container on exit.

Global remote-browser invocation (Docker required):

```bash
mix test.websocket
mix test.websocket test/core/remote_webdriver_behavior_test.exs
```

`mix test.websocket` starts/stops a Selenium container and wires `webdriver_url`
for the full test invocation.

Cross-browser conformance run:

```bash
mix test --only browser
```

`drivers: [:browser]` uses the default browser lane. You can opt specific tests into `:firefox` or `[:chrome, :firefox]` with ExUnit tags.
CI keeps chrome as the baseline browser lane and includes targeted firefox-tagged conformance coverage.

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

Migration verification docs are maintainer-focused and kept in the repository under `docs/migration-verification*.md`.
