# Browser Tests Guide

This guide covers browser-only configuration and runtime details for `session(:browser)`.

## Per-Test Browser Overrides

You can override browser defaults in one test by passing session opts:

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  user_agent: "Cerberus Mobile Spec",
  browser: [viewport: {390, 844}]
)
|> visit("/live/counter")
```

Isolation strategy:
- runtime process + BiDi transport stay shared,
- each `session(:browser, ...)` creates an isolated browser user context,
- context-level overrides (viewport/user-agent/popup mode/init scripts) are isolated per session and do not require a dedicated browser process.

SQL sandbox helper:

```elixir
metadata = Cerberus.Browser.user_agent_for_sandbox(MyApp.Repo, context)

session(:browser, user_agent: metadata)
```

`user_agent_for_sandbox/2` starts dedicated sandbox owners when needed and encodes metadata for the current test process. If browser-driven LiveViews outlive the test briefly, you can delay owner shutdown with:

```elixir
config :cerberus, ecto_sandbox_stop_owner_delay: 100
```

Concurrency limiter for `setup_all`:

```elixir
setup_all do
  Cerberus.Browser.limit_concurrent_tests()
  :ok
end
```

This keeps browser-backed modules queued behind a shared token pool without forcing the whole suite down to `mix test --max-cases 1`.

Set the default limit once in config:

```elixir
config :cerberus, :browser,
  max_concurrent_tests: 2
```

Pass `size:` to `limit_concurrent_tests/1` only when a specific limiter should override that project-wide default.
Pass `name:` only when you intentionally want multiple independent browser-test limiters.

Popup behavior:
- Preferred: use `Browser.with_popup/4` for deterministic popup capture and two-session assertions.
- `popup_mode: :allow` keeps browser default popup/new-window behavior (default).
- `popup_mode: :same_tab` injects an early preload script that rewrites `window.open(...)` to same-tab navigation.
- `:same_tab` is a pragmatic fallback for autonomous flows that you cannot reliably trigger from test callbacks.

Same-tab workaround (OAuth-style redirect/result flow):

```elixir
session(:browser, browser: [popup_mode: :same_tab])
|> visit("/browser/popup/auto")
|> assert_path("/browser/popup/destination", query: %{source: "auto-load"}, timeout: 1_500)
|> assert_has(~l"popup source: auto-load"e)
```

When workaround is brittle:
- popup behavior depends on browser security/user gesture requirements,
- popup source script changes frequently or is third-party hosted,
- flow needs asserting both opener and popup side effects.

In those cases, prefer `Browser.with_popup/4` and assert both `main` and `popup` sessions directly.

## Browser Defaults and Runtime Options

You can configure defaults once:

```elixir
config :cerberus, :timeout_ms, 300

config :cerberus, :live, timeout_ms: 700

config :cerberus, :browser, timeout_ms: 900

config :cerberus, :browser,
  ready_timeout_ms: 2_200,
  ready_quiet_ms: 40,
  bidi_command_timeout_ms: 5_000,
  runtime_http_timeout_ms: 9_000,
  screenshot_full_page: false,
  screenshot_artifact_dir: "tmp/cerberus-artifacts/screenshots",
  headless: true,
  slow_mo: 0
```

Override precedence is:
- global all-driver config (`config :cerberus, :timeout_ms, ...`)
- global per-driver config (`config :cerberus, :static | :live | :browser, timeout_ms: ...`)
- session opts (`session(timeout_ms: ...)`, `session(:browser, ready_timeout_ms: ...)`, `session(:browser, ready_quiet_ms: ...)`, context overrides in `session(:browser, browser: [...])`)
- optional Chrome-only evaluate hot path: `session(:browser, use_cdp_evaluate: true)` or `config :cerberus, :browser, use_cdp_evaluate: true`
- call opts (`assert_has(..., timeout: ...)`, `click(..., timeout: ...)`, `assert_path(..., timeout: ...)`)

Unified timeout defaults:
- Static defaults to `0ms`.
- Live defaults to `500ms`.
- Browser defaults to `500ms`.
- The same default timeout applies to assertions, actions, and path assertions.

Option scopes:
- Per-session context options: `ready_timeout_ms`, `ready_quiet_ms`, `user_agent`, `browser: [viewport: ..., user_agent: ..., popup_mode: :allow | :same_tab, init_script: ... | init_scripts: [...]]`.
- Global runtime launch options: `webdriver_url`, `chrome_webdriver_url`, `headless`, `slow_mo`, `chrome_args`, `chrome_binary`, `chromedriver_binary`.
- Global browser defaults: `bidi_command_timeout_ms`, `runtime_http_timeout_ms`, `screenshot_full_page`, `screenshot_artifact_dir`, `screenshot_path`.

Set `headless: false` to run headed mode.
Use `slow_mo` (milliseconds) to pace browser commands for debugging.

Because browser runtime + BiDi transport are shared per browser lane, runtime launch options should be treated as invocation-level config (not per-test toggles).

## Browser Runtime Setup

Cerberus browser tests use WebDriver BiDi over ChromeDriver.
Chrome is the active browser target.

Local managed runtime (default) uses configured browser and WebDriver binaries:

```elixir
config :cerberus, :browser,
  chrome_binary: "/path/to/chrome-or-chromium",
  chromedriver_binary: "/path/to/chromedriver"
```

Managed Chrome sessions use a Playwright-style Chromium switch set by default, with any configured `chrome_args` appended after those defaults.

Headed mode:

```elixir
config :cerberus, :browser, headless: false
```

Remote runtime mode:

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

With `webdriver_url` set, Cerberus does not launch local browser/WebDriver processes.

To keep the Chrome endpoint explicit:

```elixir
config :cerberus, :browser,
  chrome_webdriver_url: "http://127.0.0.1:4444"
```

Remote `webdriver_url` integration smoke test (Docker required):

```bash
CERBERUS_REMOTE_WEBDRIVER=1 mix test test/cerberus/remote_webdriver_behavior_test.exs
```

This test starts a `selenium/standalone-chromium` container with `docker run`,
connects Cerberus through `webdriver_url`, and force-removes the container on exit.

Mixed-driver local browser run:

```bash
mix test test/cerberus
```

Cerberus uses mixed-driver suites (no dedicated `:browser` tag lane), so browser coverage runs as part of normal `test/cerberus` execution.

Explicit browser-lane override coverage:

```bash
mix test test/cerberus/explicit_browser_test.exs
```

Install the local browser runtime with the public Mix task:

```bash
MIX_ENV=test mix cerberus.install.chrome --version 146.0.7680.31
```

The task installs missing binaries and reuses existing per-version installations.
Version precedence is flags first, then matching env vars (`CERBERUS_CHROME_VERSION`), then the latest stable Chrome for Testing release.

Stable output contracts:
- `--format json` for machine-readable payloads (paths, versions, env handoff keys)
- `--format env` for `KEY=VALUE` lines (for CI env files)
- `--format shell` for `export KEY='VALUE'` lines

After install, Cerberus automatically discovers local managed-runtime binaries via stable links:
- `tmp/chrome-current`
- `tmp/chromedriver-current`

No extra binary-path config is required for normal local runs after installation.

Installed paths are stable per version, for example:
- `tmp/chrome-<version>`
- `tmp/chromedriver-<version>`
