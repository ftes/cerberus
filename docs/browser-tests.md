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
- runtime process + Bibbidi-backed BiDi transport stay shared,
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
  dialog_timeout_ms: 1_500,
  screenshot_full_page: false,
  screenshot_artifact_dir: "tmp/cerberus-artifacts/screenshots",
  headless: true,
  slow_mo: 0
```

Override precedence is:
- global all-driver config (`config :cerberus, :timeout_ms, ...`)
- global per-driver config (`config :cerberus, :static | :live | :browser, timeout_ms: ...`)
- session opts (`session(timeout_ms: ...)`, `session(:browser, ready_timeout_ms: ...)`, `session(:browser, ready_quiet_ms: ...)`, context overrides in `session(:browser, browser: [...])`)
- call opts (`assert_has(..., timeout: ...)`, `click(..., timeout: ...)`, `assert_path(..., timeout: ...)`)

Unified timeout defaults:
- Static defaults to `0ms`.
- Live defaults to `500ms`.
- Browser defaults to `500ms`.
- The same default timeout applies to assertions, actions, and path assertions.

Option scopes:
- Per-session context options: `ready_timeout_ms`, `ready_quiet_ms`, `user_agent`, `browser: [viewport: ..., user_agent: ..., popup_mode: :allow | :same_tab, init_script: ... | init_scripts: [...]]`.
- Global runtime launch options: `headless`, `slow_mo`, `firefox_binary`.
- Global browser defaults: `bidi_command_timeout_ms`, `dialog_timeout_ms`, `screenshot_full_page`, `screenshot_artifact_dir`, `screenshot_path`.

Set `headless: false` to run headed mode.
Use `slow_mo` (milliseconds) to pace browser commands for debugging.

Because browser runtime + BiDi transport are shared per browser lane, runtime launch options should be treated as invocation-level config (not per-test toggles).

## Browser Runtime Setup

Cerberus browser tests use Firefox over WebDriver BiDi.
Cerberus launches Firefox directly and uses Bibbidi for the active BiDi transport layer.

Local managed runtime (default) uses the configured Firefox binary:

```elixir
config :cerberus, :browser,
  firefox_binary: "/path/to/firefox"
```

Headed mode:

```elixir
config :cerberus, :browser, headless: false
```

Mixed-driver local browser run:

```bash
mix test test/cerberus
```

Cerberus uses mixed-driver suites (no dedicated `:browser` tag lane), so browser coverage runs as part of normal `test/cerberus` execution.

Explicit browser-lane override coverage:

```bash
mix test test/cerberus/explicit_browser_test.exs
```

Install local browser runtimes with public Mix tasks:

```bash
MIX_ENV=test mix cerberus.install.firefox --firefox-version 148.0 --geckodriver-version 0.36.0
```

The install task reuses existing per-version installations.

Stable output contracts:
- `--format json` for machine-readable payloads (paths, versions, env handoff keys)
- `--format env` for `KEY=VALUE` lines (for CI env files)
- `--format shell` for `export KEY='VALUE'` lines

After install, Cerberus automatically discovers the local managed Firefox runtime via the stable link:
- `tmp/firefox-current`

No extra binary-path config is required for normal local runs after installation.

Installed paths are stable per version, for example:
- `tmp/firefox-<version>`
