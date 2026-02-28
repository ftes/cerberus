# Cerberus
![Cerberus hero artwork](docs/hero.png)

Cerberus is an experimental Phoenix testing harness with one API across:
- `:auto` (default non-browser mode with static/live auto-detection and switching),
- `:browser` (WebDriver BiDi browser-oracle mode).

Cerberus is designed for teams that want to write one feature-test flow and run it in browser and non-browser modes with minimal rewrites.

## 30-Second Start

```elixir
import Cerberus

session(:auto)
|> visit("/live/counter")
|> click(button("Increment"))
|> assert_has(text("Count: 1"), exact: true)
```

> #### Tip
>
> Start with `:auto` for most scenarios. Move to `:browser` when validating real browser behavior, keyboard/mouse APIs, or browser-only assertions.

## Progressive Examples

### 1. Static Text Assertions

```elixir
session(:auto)
|> visit("/articles")
|> assert_has(text("Articles"), exact: true)
|> refute_has(text("500 Internal Server Error"), exact: true)
```

### 2. LiveView Interaction

```elixir
session(:auto)
|> visit("/live/counter")
|> click(role(:button, name: "Increment"))
|> assert_has(text("Count: 1"), exact: true)
```

### 3. Form + Path Assertions

```elixir
session(:auto)
|> visit("/search")
|> fill_in(label("Search term"), "Aragorn")
|> submit(button("Run Search"))
|> assert_path("/search/results", query: %{q: "Aragorn"})
|> assert_has(text("Search query: Aragorn"), exact: true)
```

### 4. Scope + Navigation

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

### 5. Multi-User + Multi-Tab

```elixir
primary =
  session(:auto)
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
|> assert_has(text("Press result: submitted"), exact: true)
|> assert_has(text("Dialog result: cancelled"), exact: true)
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

The same flow usually works in both modes:

```elixir
flow = fn mode ->
  session(mode)
  |> visit("/live/counter")
  |> click(button("Increment"))
  |> assert_has(text("Count: 1"), exact: true)
end

flow.(:auto)
flow.(:browser)
```

## Learn More

- [Getting Started Guide](docs/getting-started.md)
- [Cheat Sheet](docs/cheatsheet.md)
- [Architecture and Driver Model](docs/architecture.md)

## Browser Runtime Setup

Cerberus browser tests use WebDriver BiDi with explicit binaries.

Required env vars:
- `CHROME`
- `CHROMEDRIVER`

Optional:
- `SHOW_BROWSER=true` to run headed.

Project helper:

```bash
bin/check_bidi_ready.sh --install
```

The helper installs pinned local Chrome for Testing + ChromeDriver under `tmp/browser-tools`, validates version parity, and verifies `webSocketUrl` BiDi handshake support.

## Migration Task

Cerberus includes an Igniter migration task for PhoenixTest codebases:

```bash
mix igniter.cerberus.migrate_phoenix_test
mix igniter.cerberus.migrate_phoenix_test --write test/my_app_web/features
```

It performs safe rewrites, reports manual follow-ups, and defaults to dry-run diff output.
