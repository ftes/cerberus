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
> `session(conn)` reuses an existing `Plug.Conn` (including carried session/cookie state) instead of starting from a fresh conn.
> For browser mode, `session(:browser)` defaults to Chrome; use `session(:chrome)` or `session(:firefox)` for explicit targets.
> Project CI currently runs Chrome lanes only. Firefox runs are supported, but opt-in.

Set the endpoint once globally (same style as PhoenixTest), then use plain `session()` in tests:

```elixir
# test/test_helper.exs
Application.put_env(:cerberus, :endpoint, MyAppWeb.Endpoint)
```

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

## Locator Basics (Phoenix/LiveView First)

A locator is how Cerberus finds elements for actions and assertions.

Start with the most user-facing option that is stable in your UI:
- form label text for form actions (`fill_in/3`, `check/2`, `choose/2`, `select/3`)
- role + accessible name for interactive controls (`button`, `link`, etc.)
- visible text for content assertions
- `testid`/`css` only when user-facing text is ambiguous or intentionally hidden

Examples:

```elixir
session()
|> visit("/settings")
|> fill_in("Email", "alice@example.com")
|> check("Receive updates")
|> click(~l"button:Save"r)
|> assert_has(~l"Settings saved"e)
```

When a page has repeated labels/buttons, scope first:

```elixir
session()
|> visit("/checkout")
|> within(~l"#shipping-address"c, fn scoped ->
  scoped
  |> fill_in("City", "Berlin")
  |> click(~l"button:Save"r)
end)
```

Use `testid` when text/role cannot disambiguate reliably:

```elixir
session()
|> visit("/live/selector-edge")
|> click(testid("apply-secondary-button"))
|> assert_has(~l"Selected: secondary"e)
```

Locator sigil quick look:
- `~l"Save"` text
- `~l"Save"e` exact text
- `~l"Save"i` inexact text
- `~l"button:Save"r` role form (`ROLE:NAME`)
- `~l"button[type='submit']"c` css form
- `~l"Run search"a` aria-label form
- `~l"save-button"t` testid form (`exact: true` default)
- at most one kind modifier (`r`, `c`, `a`, or `t`)
- `e` and `i` are mutually exclusive
- `r` requires `ROLE:NAME`

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
session() # or session(conn)
|> visit("/live/selector-edge")
|> fill_in("Name", "primary", first: true, count: 2)
|> fill_in("Name", "secondary", last: true, count: 2)
```

## Advanced Locator Composition (Optional)

You can compose locators when simple label/role/testid matching is not enough.

Common advanced patterns:
- same-element AND (pipe composition): `button("Run Search") |> testid("submit-secondary-button")`
- descendant requirement: `button("Run Search") |> has(testid("submit-secondary-marker"))`
- OR alternatives: `or_(css("#primary"), css("#secondary"))`

```elixir
session()
|> visit("/live/selector-edge")
|> click(button("Apply") |> testid("apply-secondary-button"))
|> assert_has(~l"Selected: secondary"e)
```

`closest/2` is useful for Phoenix wrapper patterns where you want the nearest ancestor around another locator (for example, a fieldset around a label/control):

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
> In browser mode, text/path assertions run wait loops in browser JS and Cerberus adds bounded transient eval retries for navigation/context-reset races.

## Step 7: Browser-Only Extensions

```elixir
import Cerberus.Browser

session =
  session(:browser)
  |> visit("/browser/extensions")
  |> type("hello", selector: "#keyboard-input")
  |> press("Enter", selector: "#press-input")

evaluate_js(session, "setTimeout(() => document.getElementById('confirm-dialog')?.click(), 10)")

session =
  session
  |> assert_dialog(~l"Delete item?"e)

session
|> assert_has(~l"Press result: submitted"e)
|> assert_has(~l"Dialog result: cancelled"e)
```

## Step 8: Per-Test Browser Overrides

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  user_agent: "Cerberus Mobile Spec",
  browser: [viewport: {390, 844}]
)
|> visit("/live/counter")
|> assert_has(~l"Count: 1")
```

Use this when one test needs different browser characteristics (for example mobile viewport) without changing global config.

SQL sandbox user-agent helper:

```elixir
metadata = Cerberus.sql_sandbox_user_agent(MyApp.Repo, context)

session(:browser, user_agent: metadata)
```

## Step 9: Install Local Browser Runtimes

Install browser binaries with Cerberus Mix tasks:

```bash
mix cerberus.install.chrome
mix cerberus.install.firefox
```

For explicit versions:

```bash
mix cerberus.install.chrome --version 146.0.7680.31
mix cerberus.install.firefox --firefox-version 148.0 --geckodriver-version 0.36.0
```

The tasks expose stable output formats:
- `--format json` for machine-readable payloads
- `--format env` for CI (`KEY=VALUE`)
- `--format shell` for local shell exports

Recommended shell handoff:

```bash
eval "$(mix cerberus.install.chrome --format shell)"
eval "$(mix cerberus.install.firefox --format shell)"
```

Cerberus also writes stable local links on install (`tmp/chrome-current`, `tmp/chromedriver-current`, `tmp/firefox-current`, `tmp/geckodriver-current`), so local managed browser runs work without extra binary-path config.

## Step 10: Remote WebDriver Mode

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
For regular project runs, use Chrome-first invocations unless you are explicitly validating Firefox behavior.

## Step 11: Headed Browser and Runtime Launch Options

```elixir
config :cerberus, :browser,
  show_browser: true
```

`show_browser: true` runs headed by default.
If both are set, `headless` takes precedence over `show_browser`.

Runtime launch settings (for example `show_browser`, `headless`, browser binaries, driver binaries, `webdriver_url`, `chrome_webdriver_url`, and `firefox_webdriver_url`) are runtime-level and should be configured globally per test invocation, not per test.
