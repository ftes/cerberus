# Cerberus
Fast Phoenix feature tests with real-browser confidence.

[![Hex.pm Version](https://img.shields.io/hexpm/v/cerberus)](https://hex.pm/packages/cerberus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cerberus/)
[![License](https://img.shields.io/hexpm/l/cerberus.svg)](https://github.com/ftes/cerberus/blob/main/LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ftes/cerberus/ci.yml)](https://github.com/ftes/cerberus/actions)

![Cerberus hero artwork](docs/banner.avif)

Single API to feature test
1. LiveViews
2. Controllers (static/dead views)
3. In Browser

Vertically integrated: It's like PhoenixTest + Playwright. Or Capybara + Cuprite. Why you ask?
1. **You can** easily switch from non-browser tests (fast!) to browser tests when you add JS hooks.
2. **We can** guarantee correctness: Phoenix drivers are tested against real browser behaviour.

## 30-Second Start
```ex
# mix.exs
{:cerberus, "~> 0.1"}
```

```bash
sh> MIX_ENV=test mix cerberus.install.chrome
```

```elixir
import Cerberus

session
|> visit("/auth/static/users/log_in")
|> fill_in(~l"Email", "frodo@example.com")
|> assert_value(~l"Email"l, "frodo@example.com")
|> fill_in(~l"Password", "shire-secret")
|> submit(~l"Log in"e)
|> assert_has(~l"Signed in as: frodo@example.com"e)


import Cerberus.Browser

session(:browser, headless: false, slow_mo: 500) # open chrome
|> visit("/live/counter")
|> with_evaluate_js("document.body.dataset.cerberus = 'ready'", fn _ -> :ok end)
|> with_screenshot(full_page: true, open: true)
```

For progressive, step-by-step examples (scopes, forms, tabs, browser extensions), see [Getting Started](docs/getting-started.md).

## Helpful errors

When an action/assertion misses, Cerberus includes likely alternatives.

```elixir
session()
|> visit("/search")
|> submit(~l"Definitely Missing Submit"e)
```

```text
submit failed: no submit button matched locator
locator: %Cerberus.Locator{kind: :text, value: "Definitely Missing Submit", opts: [exact: true]}
...
possible candidates:
  - "Run Search"
  - "Run Nested Search"
```

## Locators

A locator is the way Cerberus finds elements or text in the UI.

Use composable locator functions when matching needs structure (`label`, `role`, `text`, `filter`, `and_`, `closest`, ...).
Use `~l` sigil shorthand for common one-liners:
- `~l"Save"` means exact text match by default
- `~l"Save"i` means inexact text match
- `~l"button:Save"r` means role + accessible name
- text-like matches normalize whitespace by default (`normalize_ws: true`), including NBSP characters
- set `normalize_ws: false` when you need exact raw whitespace matching

Use `~l"..."t` when text/role is ambiguous, and `~l"..."c` only for structural targeting.

For locator forms and advanced composition (`~l` modifiers, `and_`, `or_`, `not_`, `filter`, `closest`), see:
- [Cheat Sheet](docs/cheatsheet.md)
- [Getting Started](docs/getting-started.md)

## Debugging

```elixir
session()
|> visit("/articles")
|> open_browser() # 1) human: open static HTML snapshot in browser
|> with_render_html(&IO.inspect(LazyHTML.query(&1, "h1"))) # 2) AI: inspect static HTML snapshot

session(:browser, show_browser: true, slow_mo: 500) # 3) human: watch live interaction in browser
|> visit("/articles")
|> with_evaluate_js("document.body.dataset.cerberus = 'ready'", fn _ -> :ok end)

png =
  session(:browser)
  |> visit("/articles")
  |> screenshot(path: "tmp/page.png") # raw PNG bytes
```

## Browser Tests

Start in Phoenix mode (static/live) for fast feedback, then switch to browser mode when you add JS-dependent behavior (custom snippets, drag/drop, popup flows). In many tests this is just changing `session()` to `session(:browser)`.
`visit/2` waits for post-navigation browser readiness and auto-detects LiveView roots (`[data-phx-session]`), only waiting for `phx-connected` when a LiveView is present. Other browser actions rely on browser actionability and on the next action/assertion to wait for whatever state it needs.

Install Chrome with:

```bash
MIX_ENV=test mix cerberus.install.chrome
```

That task is simple to run in CI setup steps too.

Most tests only need `session(:browser)`; deeper runtime/config details are documented in [Browser Support Policy](docs/browser-support-policy.md).

When browser-backed modules need bounded concurrency, configure `config :cerberus, :browser, max_concurrent_tests: ...` and call `Cerberus.Browser.limit_concurrent_tests/1` from `setup_all`. Most suites can use the defaults with no options. The full pattern is documented in [Browser Tests Guide](docs/browser-tests.md).

## Portal Support

Cerberus supports portal-backed LiveView button clicks in both the live and browser drivers.

Current scope:
- `click/2` and `click/3` on portal-backed buttons are supported.
- Broader portal interactions are not fully generalized yet. For portal forms, `within` scopes, or more complex teleported flows, use `session(:browser)`.

## Performance

- Non-browser Phoenix mode is the fast lane for most feature tests.
- Browser assertions/path checks run polling in browser JS and include bounded retry handling for navigation/context-reset races.
- Browser-mode throughput is in the same class as Playwright-style real-browser E2E (both pay real browser/runtime costs), while Cerberus keeps one API across both lanes.

## Difference To PhoenixTest

- Faster Phoenix lane for most feature tests, especially when staying out of the browser.
- One session-first API across static controllers, LiveView, and browser tests.
- Browser-backed parity tests keep Phoenix-mode semantics aligned with real browser behavior.
- Built-in Chrome driver, so browser coverage does not require a separate test tool.
- Richer locators (`role`, `label`, `testid`, composition, filters) for more precise intent.
- Portal-backed LiveView button clicks work in both Phoenix and browser drivers.

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Browser Support Policy](docs/browser-support-policy.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)
