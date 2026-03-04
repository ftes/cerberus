# Cerberus

[![Hex.pm Version](https://img.shields.io/hexpm/v/cerberus)](https://hex.pm/packages/cerberus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cerberus/)
[![License](https://img.shields.io/hexpm/l/cerberus.svg)](https://github.com/ftes/cerberus/blob/main/LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ftes/cerberus/ci.yml)](https://github.com/ftes/cerberus/actions)

![Cerberus hero artwork](docs/hero.avif)

Ship Phoenix feature tests fast without losing browser truth.

Cerberus is vertically integrated. Think of it as
- Phoenix-aware test APIs (PhoenixTest / PhoenixTest.Playwright)
- plus lower-level browser drivers (Capybara + Cuprite / Playwright).

Why integrate?
1. You can easily switch from non-browser tests (fast!) to browser tests when you add JS hooks.
2. We can guarantee correctness: Phoenix driver behaviour is tested against real browser behaviour.

## 30-Second Start
```ex
# mix.exs
{:cerberus, "~> 0.1"}
```

```bash
sh> mix cerberus.install.chrome
```

```elixir
import Cerberus

session
|> visit("/live/counter")
|> click(~l"button:Increment"r) # role locator
|> assert_has(~l"Count: 1"e) # e = exact text match


import Cerberus.Browser

session(:browser, headless: false, slow_mo: 500) # open chrome
|> visit("/live/counter")
|> evaluate_js("prompt('Hey!')")
|> screenshot(full_page: true)
```

For progressive, step-by-step examples (scopes, forms, tabs, browser extensions), see [Getting Started](docs/getting-started.md).

## Helpful errors

When an action/assertion misses, Cerberus includes likely alternatives.

```elixir
session()
|> visit("/search")
|> submit(text: "Definitely Missing Submit")
```

```text
submit failed: no submit button matched locator
locator: [text: "Definitely Missing Submit"]
...
possible candidates:
  - "Run Search"
  - "Run Nested Search"
```

## Locators

A locator is the way Cerberus finds elements or text in the UI.

Use composable locator functions when matching needs structure (`label`, `button`, `text`, `has`, `and_`, `closest`, ...).
Use `~l` sigil shorthand for common one-liners:
- `~l"Save"e` means exact text match (`e` = exact)
- `~l"button:Save"r` means role + accessible name

Use `testid(...)` when text/role is ambiguous, and CSS for structural targeting only.

For locator forms and advanced composition (`~l` modifiers, `and_`, `or_`, `not_`, `has`, `has_not`, `closest`), see:
- [Cheat Sheet](docs/cheatsheet.md)
- [Getting Started](docs/getting-started.md)

## Debugging

```elixir
session()
|> visit("/articles")
|> open_browser() # 1) human: open static HTML snapshot in browser
|> render_html(&IO.inspect(LazyHTML.query(&1, "h1"))) # 2) AI: inspect static HTML snapshot

session(:browser, show_browser: true, slow_mo: 500) # 3) human: watch live interaction in browser
|> visit("/articles")
|> screenshot(full_page: true) # 4) human and AI: static .png screenshot
```

## Browser Tests

Start in Phoenix mode (static/live) for fast feedback, then switch to browser mode when you add JS-dependent behavior (custom snippets, dialogs, drag/drop, popup flows). In many tests this is just changing `session()` to `session(:browser)`.

Install Chrome with:

```bash
mix cerberus.install.chrome
```

That task is simple to run in CI setup steps too.

Most tests only need `session(:browser)`; deeper runtime/config details are documented in [Browser Support Policy](docs/browser-support-policy.md).

## Performance

- Non-browser Phoenix mode is the fast lane for most feature tests.
- Browser assertions/path checks run polling in browser JS and include bounded retry handling for navigation/context-reset races.
- Browser-mode throughput is in the same class as Playwright-style real-browser E2E (both pay real browser/runtime costs), while Cerberus keeps one API across both lanes.

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Browser Support Policy](docs/browser-support-policy.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)

## Migration Task

Cerberus includes an Igniter migration task for PhoenixTest codebases:

```bash
mix cerberus.migrate_phoenix_test
mix cerberus.migrate_phoenix_test --write test/my_app_web/features
```

It performs safe rewrites, reports manual follow-ups, and defaults to dry-run diff output.

Migration verification docs are maintainer-focused and kept in the repository under `docs/migration-verification*.md`.
