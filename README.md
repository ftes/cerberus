# Cerberus

[![Hex.pm Version](https://img.shields.io/hexpm/v/cerberus)](https://hex.pm/packages/cerberus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cerberus/)
[![License](https://img.shields.io/hexpm/l/cerberus.svg)](https://github.com/ftes/cerberus/blob/main/LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ftes/cerberus/ci.yml)](https://github.com/ftes/cerberus/actions)

![Cerberus hero artwork](docs/hero.avif)

Cerberus is an experimental Phoenix testing library with one API across:
- non-browser Phoenix mode with static/live auto-detection and switching,
- browser mode for Chrome and Firefox via WebDriver BiDi.

Minimal API: You control your tests. Easily run single tests/describe blocks/entire modules in one or more browsers.

## Performance Highlight

Live (non-browser) assertions are optimized for large pages:
- `assert_has` / `refute_has` in live mode read from LiveViewTest's internal patched DOM tree,
- they avoid the previous `render(view)` -> HTML string -> LazyHTML re-parse loop on each assertion,
- matcher semantics stay in Cerberus so locators/matching remain consistent across drivers.

Browser assertions/path checks use an in-browser wait loop as the fast path:
- assertion/path polling happens inside browser JS (not Elixir-side polling),
- Cerberus adds a bounded transient retry wrapper when BiDi eval hits navigation/context-reset races,
- retries keep the original timeout budget semantics while reducing flaky transition failures.

## 30-Second Start
```ex
# mix.exs
{:cerberus, "~> 0.1"}
```

```bash
mix cerberus.install.chrome
```

```elixir
import Cerberus

session
|> visit("/live/counter")
|> click(~l"button:Increment"r)
|> assert_has(~l"Count: 1"e)

session(:browser, show_browser: true) # open chrome
|> visit("/live/counter")
|> evaluate_js("prompt('Hey!')")
```

For progressive, step-by-step examples (scopes, forms, tabs, browser extensions), see [Getting Started](docs/getting-started.md).

## Failure Diagnostics

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

## Locator Quick Look

Prefer user-facing selectors first:
- labels for form actions (`fill_in(label("Email"), "...")`)
- role + accessible name for controls (`~l"button:Save"r`)
- visible text for assertions (`assert_has(~l"Saved"e)`)

Use `testid(...)` when text/role is ambiguous, and CSS for structural targeting only.

For locator forms and advanced composition (`~l` modifiers, `and_`, `or_`, `not_`, `has`, `has_not`, `closest`), see:
- [Cheat Sheet](docs/cheatsheet.md)
- [Getting Started](docs/getting-started.md)

## Debugging Snapshots

```elixir
session = session() |> visit("/articles")

session
|> open_browser() # 1) human debugging: open rendered HTML in your local browser

session
|> render_html(fn lazy_html ->
  IO.inspect(LazyHTML.query(lazy_html, "h1"))
end) # 2) in-process DOM access for AI/tooling workflows
```

## Browser Tests

Browser-specific configuration and runtime setup live in [Browser Support Policy](docs/browser-support-policy.md):
- per-test browser overrides
- browser defaults and option precedence
- local/remote runtime setup and install tasks

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Browser Support Policy](docs/browser-support-policy.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)
- [Browser Support Policy](docs/browser-support-policy.md)

## Migration Task

Cerberus includes an Igniter migration task for PhoenixTest codebases:

```bash
mix cerberus.migrate_phoenix_test
mix cerberus.migrate_phoenix_test --write test/my_app_web/features
```

It performs safe rewrites, reports manual follow-ups, and defaults to dry-run diff output.

Migration verification docs are maintainer-focused and kept in the repository under `docs/migration-verification*.md`.
