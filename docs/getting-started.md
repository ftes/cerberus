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
> `session(:browser)` is the public browser entrypoint and runs Chrome.

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
|> fill_in(~l"Search term", "Aragorn")
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

Scoped text assertions use explicit locator arguments:

```elixir
session()
|> visit("/scoped")
|> assert_has(~l"#secondary-panel"c, ~l"Status: secondary"e)
|> refute_has(~l"#secondary-panel"c, ~l"Status: primary"e)
```

Scoped assertion overloads use explicit scope and locator arguments:
- `assert_has(session, scope_locator, locator, opts \\ [])`
- `refute_has(session, scope_locator, locator, opts \\ [])`

State assertions are available as direct helpers:

```elixir
session()
|> visit("/phoenix_test/page/index")
|> assert_checked(~l"Mail Choice"l)
|> refute_checked(~l"Email Choice"l)
|> assert_disabled(~l"Disabled textaread"l)
|> assert_readonly(~l"Readonly notes"l)
```

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
|> fill_in(~l"Email", "alice@example.com")
|> check(~l"Receive updates")
|> click(~l"button:Save"r)
|> assert_has(~l"Settings saved"e)
```

When a page has repeated labels/buttons, scope first:

```elixir
session()
|> visit("/checkout")
|> within(~l"#shipping-address"c, fn scoped ->
  scoped
  |> fill_in(~l"City", "Berlin")
  |> click(~l"button:Save"r)
end)
```

Use `testid` when text/role cannot disambiguate reliably:

```elixir
session()
|> visit("/live/selector-edge")
|> click(~l"apply-secondary-button"t)
|> assert_has(~l"Selected: secondary"e)
```

Locator sigil quick look:
- `~l"Save"` exact text (default)
- `~l"Save"e` exact text
- `~l"Save"i` inexact text
- `~l"Email"l` field label form (`<label>`, `aria-labelledby`, or `aria-label`)
- `~l"button:Save"r` role form (`ROLE:NAME`)
- `~l"button[type='submit']"c` css form
- `~l"save-button"t` testid form (`exact: true` default)
- at most one kind modifier (`r`, `c`, `l`, or `t`)
- `e` and `i` are mutually exclusive
- `r` requires `ROLE:NAME`
- regex values are supported for text-like locators and role names, but cannot be combined with `exact: true|false`

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

Browser actions additionally support:
- `force: true` (bypass browser actionability checks for the targeted action)

Default actionability behavior:
- browser actions wait for matched controls to become enabled before acting
- live actions retry briefly when a matched form control is still disabled after a preceding LiveView update
- static actions do not wait; disabled controls fail immediately

Example:

```elixir
session() # or session(conn)
|> visit("/live/selector-edge")
|> fill_in(~l"Name", "primary", first: true, count: 2)
|> fill_in(~l"Name", "secondary", last: true, count: 2)
```

## Advanced Locator Composition (Optional)

You can compose locators when simple label/role/testid matching is not enough.

Common advanced patterns:
- scope chaining (descendant query): `~l"#search-form"c |> scope(~l"button:Run Search"r)`
- same-element intersection: `and_(~l"button:Run Search"r, ~l"submit-secondary-button"t)`
- descendant requirement: `~l"button:Run Search"r |> filter(has: ~l"submit-secondary-marker"t)`
- descendant exclusion: `~l"button:Run Search"r |> filter(has_not: ~l"submit-secondary-marker"t)`
- visibility constraint: `~l"button:Run Search"r |> filter(visible: true)`
- OR alternatives: `or_(~l"#primary"c, ~l"#secondary"c)`
- boolean algebra: `and_(~l"button:Run Search"r, not_(~l"submit-secondary-button"t))`
- negated conjunction: `not_(and_(~l"button:Run Search"r, ~l"submit-secondary-button"t))`

```elixir
session()
|> visit("/live/selector-edge")
|> click(and_(~l"button:Apply"r, ~l"apply-secondary-button"t))
|> assert_has(~l"Selected: secondary"e)
```

`closest/2` is useful for Phoenix wrapper patterns where you want the nearest ancestor around another locator (for example, a fieldset around a label/control):

```elixir
session()
|> visit("/field-wrapper-errors")
|> assert_has(closest(~l".fieldset"c, from: ~l"textbox:Email"r), ~l"can't be blank"e)
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
|> assert_has(~l"Title loaded async"e)
```

> #### Tip
>
> Timeouts are unified across assertions, actions, and path assertions.
> Default timeout precedence is: global all-driver config, then global per-driver config, then session `timeout_ms`, then call `timeout: ...`.
> The built-in defaults are `0ms` for static and `500ms` for live/browser.
> Static assertions are one-shot.
> Live assertions and actions wait on LiveView progress before retrying.
> Browser assertions and actions wait natively in the browser driver rather than through a shared outer timeout loop.

## Step 7: Browser-Only Extensions

```elixir
import Cerberus.Browser

session =
  session(:browser)
  |> visit("/browser/extensions")
  |> type(~l"#keyboard-input"c, "hello")
  |> press(~l"#press-input"c, "Enter")
evaluate_js(session, "window.__cerberusMarker = 'ready'")

session
|> assert_has(~l"Press result: submitted"e)

png =
  screenshot(session, path: "tmp/extensions.png")

cookie(session, "_cerberus_fixture_key", fn entry ->
  assert entry
end)

session
|> add_session_cookie(
  [value: %{session_user: "alice"}],
  Cerberus.Fixtures.Endpoint.session_options()
)
|> visit("/session/user")
|> assert_has(~l"Session user: alice"e)
```

## Step 8: Per-Test Browser Overrides

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  user_agent: "Cerberus Mobile Spec",
  browser: [viewport: {390, 844}]
)
|> visit("/live/counter")
|> assert_has(~l"Count: 1"e)
```

Use this when one test needs different browser characteristics (for example mobile viewport) without changing global config.

SQL sandbox user-agent helper:

```elixir
metadata = Cerberus.Browser.user_agent_for_sandbox(MyApp.Repo, context)

session(:browser, user_agent: metadata)

# Optional: delay sandbox-owner shutdown for LiveView-heavy browser tests.
config :cerberus, ecto_sandbox_stop_owner_delay: 100
```

## Step 9: Install Local Browser Runtimes

Install browser binaries with Cerberus Mix tasks:

```bash
MIX_ENV=test mix cerberus.install.chrome
```

For explicit versions:

```bash
MIX_ENV=test mix cerberus.install.chrome --version 146.0.7680.31
```

Cerberus writes stable local links on install (`tmp/chrome-current`, `tmp/chromedriver-current`, `tmp/firefox-current`), so local managed browser runs work without extra binary-path config.

## Step 10: Remote WebDriver Mode

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

Remote mode connects to an already-running WebDriver endpoint and skips local browser/WebDriver launch.

To keep one global remote Chrome lane while still making the browser endpoint explicit:

```elixir
config :cerberus, :browser,
  chrome_webdriver_url: "http://127.0.0.1:4444"
```

To run Firefox instead:

```elixir
config :cerberus, :browser,
  browser_name: :firefox,
  firefox_binary: "/path/to/firefox"
```

Or keep the Firefox remote endpoint explicit:

```elixir
config :cerberus, :browser,
  browser_name: :firefox,
  firefox_webdriver_url: "http://127.0.0.1:4444"
```

## Step 11: Headed Browser and Runtime Launch Options

```elixir
config :cerberus, :browser,
  headless: false
```

`headless: false` runs headed mode.

`slow_mo` adds a fixed delay (in milliseconds) before each browser BiDi command:

```elixir
config :cerberus, :browser,
  slow_mo: 120
```

Runtime launch settings (for example `browser_name`, `headless`, `slow_mo`, browser binaries, driver binaries, `webdriver_url`, `chrome_webdriver_url`, and `firefox_webdriver_url`) are runtime-level and should be configured globally per test invocation, not per test.
