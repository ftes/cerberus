# Getting Started

This guide moves from the smallest working Cerberus flow to advanced multi-session scenarios.

## Core Mental Model

Cerberus is session-first. Every operation returns an updated session.

```elixir
session()
|> visit("/articles")
|> assert_has(~l"Articles"e)
```

> #### Info
>
> `session()` (or explicit `session(:phoenix)`) gives a PhoenixTest-style flow: static and live routes are handled automatically behind one API.
> For browser mode, `session(:browser)` defaults to Chrome; use `session(:chrome)` or `session(:firefox)` for explicit targets. Chrome and Firefox are both first-class supported targets.

## Step 1: First Useful Flow

```elixir
session()
|> visit("/articles")
|> assert_has(~l"Articles"e)
|> refute_has(~l"500 Internal Server Error"e)
```

## Step 2: LiveView Interaction (Same API)

```elixir
session()
|> visit("/live/counter")
|> click(~l"button:Increment"r)
|> assert_has(~l"Count: 1"e)
```

## Step 3: Forms + Path Assertions

```elixir
session()
|> visit("/search")
|> fill_in("Search term", "Aragorn")
|> submit(~l"button:Run Search"r)
|> assert_path("/search/results", query: %{q: "Aragorn"})
|> assert_has(~l"Search query: Aragorn"e)
```

## Step 4: Scoped Interaction

```elixir
session()
|> visit("/scoped")
|> within(~l"#secondary-panel"c, fn scoped ->
  scoped
  |> assert_has(~l"Status: secondary"e)
  |> click(~l"link:Open"r)
end)
|> assert_path("/search")
```

`within/3` expects locator input (`~l"#panel"c`, `~l"button:Open"r`, `~l"search-input"t`, etc.). Browser locator scopes can switch into same-origin iframes.

Locator sigil quick look:
- `~l"Save"` text
- `~l"Save"e` exact text
- `~l"Save"i` inexact text
- `~l"button:Save"r` role form (`ROLE:NAME`)
- `~l"button[type='submit']"c` css form
- `~l"save-button"t` testid form (`exact: true` default)
- at most one kind modifier (`r`, `c`, or `t`)
- `e` and `i` are mutually exclusive
- `r` requires `ROLE:NAME`

Scoped text assertions also support plain-string shorthand:

```elixir
session()
|> visit("/scoped")
|> assert_has(~l"#secondary-panel"c, "Status: secondary")
|> refute_has(~l"#secondary-panel"c, "Status: primary")
```

Scoped assertion overloads use explicit scope and locator arguments:
- `assert_has(session, scope_locator, locator, opts \\ [])`
- `refute_has(session, scope_locator, locator, opts \\ [])`

## Match Count And Position Filters

Locator operations support shared count filters:

- `count: n`
- `min: n`
- `max: n`
- `between: {min, max}` or `between: min..max`

Element-targeting actions also support position filters:

- `first: true`
- `last: true`
- `nth: n` (1-based)
- `index: n` (0-based)

Example:

```elixir
session()
|> visit("/live/selector-edge")
|> fill_in("Name", "primary", first: true, count: 2)
|> fill_in("Name", "secondary", last: true, count: 2)
```

## Locator Composition With has

You can require nested descendants while resolving a locator by passing `has:` with a nested locator (`label(...)`, `css(...)`, `text(...)`, `testid(...)`, and other helper kinds).

```elixir
session()
|> visit("/live/selector-edge")
|> click(button("Apply", has: testid("apply-secondary-marker")))
|> assert_has(~l"Selected: secondary"e)
```

Use `closest/2` when the scope should resolve to the nearest matching ancestor around a nested locator (for example, a field wrapper around a label):

```elixir
session()
|> visit("/field-wrapper-errors")
|> assert_has(closest(~l".fieldset"c, from: ~l"textbox:Email"r), ~l"can't be blank")
```

## Step 5: Multi-User + Multi-Tab

```elixir
primary =
  session()
  |> visit("/session/user/alice")
  |> assert_has(~l"Session user: alice"e)

_tab2 =
  primary
  |> open_tab()
  |> visit("/session/user")
  |> assert_has(~l"Session user: alice"e)

session()
|> visit("/session/user")
|> assert_has(~l"Session user: unset"e)
|> refute_has(~l"Session user: alice"e)
```

## Step 6: Async LiveView Assertions

```elixir
session()
|> visit("/live/async_page")
|> assert_has(~l"Title loaded async")
```

> #### Tip
>
> Live and browser assertion APIs default to a `500ms` timeout budget (`assert_*` and `refute_*`, including path assertions).
> You can override per call (`timeout: ...`), per session (`session(assert_timeout_ms: ...)`), or globally (`config :cerberus, :assert_timeout_ms, ...`).

## Step 7: Browser-Only Extensions

```elixir
import Cerberus.Browser

session =
  session(:browser)
  |> visit("/browser/extensions")
  |> type("hello", selector: "#keyboard-input")
  |> press("Enter", selector: "#press-input")
  |> with_dialog(fn dialog_session ->
    click(dialog_session, ~l"button:Open Confirm Dialog"r)
  end)

session
|> assert_has(~l"Press result: submitted"e)
|> assert_has(~l"Dialog result: cancelled"e)
```

## Step 8: Per-Test Browser Overrides

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  browser: [viewport: {390, 844}, user_agent: "Cerberus Mobile Spec"]
)
|> visit("/live/counter")
|> assert_has(~l"Count: 1")
```

Use this when one test needs different browser characteristics (for example mobile viewport) without changing global config.

## Step 9: Remote WebDriver Mode

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

Remote mode connects to an already-running WebDriver endpoint and skips local browser/WebDriver launch.

To point specific browser lanes at different remote endpoints:

```elixir
config :cerberus, :browser,
  chrome_webdriver_url: "http://127.0.0.1:4444",
  firefox_webdriver_url: "http://127.0.0.1:5555"
```

For containerized websocket-style remote runs:

```bash
mix test.websocket
mix test.websocket --browsers chrome,firefox
```

`mix test.websocket` defaults to `--browsers all`.

## Step 10: Headed Browser and Runtime Launch Options

```elixir
config :cerberus, :browser,
  show_browser: true
```

`show_browser: true` runs headed by default.
If both are set, `headless` takes precedence over `show_browser`.

Runtime launch settings (for example `show_browser`, `headless`, browser binaries, driver binaries, `webdriver_url`, `chrome_webdriver_url`, and `firefox_webdriver_url`) are runtime-level and should be configured globally per test invocation, not per test.
