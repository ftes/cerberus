# Getting Started

This guide moves from the smallest working Cerberus flow to advanced multi-session scenarios.

## Core Mental Model

Cerberus is session-first. Every operation returns an updated session.

```elixir
session()
|> visit("/articles")
|> assert_has(text("Articles", exact: true))
```

> #### Info
>
> `session()` (or explicit `session(:phoenix)`) gives a PhoenixTest-style flow: static and live routes are handled automatically behind one API.
> For browser mode, `session(:browser)` defaults to Chrome; use `session(:chrome)` or `session(:firefox)` for explicit targets. Chrome and Firefox are both first-class supported targets.

## Step 1: First Useful Flow

```elixir
session()
|> visit("/articles")
|> assert_has(text("Articles", exact: true))
|> refute_has(text("500 Internal Server Error", exact: true))
```

## Step 2: LiveView Interaction (Same API)

```elixir
session()
|> visit("/live/counter")
|> click(button("Increment"))
|> assert_has(text("Count: 1", exact: true))
```

## Step 3: Forms + Path Assertions

```elixir
session()
|> visit("/search")
|> fill_in(label("Search term"), "Aragorn")
|> submit(button("Run Search"))
|> assert_path("/search/results", query: %{q: "Aragorn"})
|> assert_has(text("Search query: Aragorn", exact: true))
```

## Step 4: Scoped Interaction

```elixir
session()
|> visit("/scoped")
|> within("#secondary-panel", fn scoped ->
  scoped
  |> assert_has(text("Status: secondary", exact: true))
  |> click(link("Open"))
end)
|> assert_path("/search")
```

## Step 5: Multi-User + Multi-Tab

```elixir
primary =
  session()
  |> visit("/session/user/alice")
  |> assert_has(text("Session user: alice", exact: true))

_tab2 =
  primary
  |> open_tab()
  |> visit("/session/user")
  |> assert_has(text("Session user: alice", exact: true))

primary
|> open_user()
|> visit("/session/user")
|> assert_has(text("Session user: unset", exact: true))
|> refute_has(text("Session user: alice", exact: true))
```

## Step 6: Async LiveView Assertions

```elixir
session()
|> visit("/live/async_page")
|> assert_has(text("Title loaded async"))
```

> #### Tip
>
> Live and browser assertion APIs default to a `500ms` timeout budget (`assert_*` and `refute_*`, including path assertions).
> You can override per call (`timeout: ...`), per session (`session(assert_timeout_ms: ...)`), or globally (`config :cerberus, :assert_timeout_ms, ...`).

## Step 7: Browser-Only Extensions

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
|> assert_has(text("Press result: submitted", exact: true))
|> assert_has(text("Dialog result: cancelled", exact: true))
```

> #### Warning
>
> `Cerberus.Browser.*` APIs are intentionally browser-only and raise explicit unsupported-operation assertions on non-browser sessions.

## Step 8: Per-Test Browser Overrides

```elixir
session(:browser,
  ready_timeout_ms: 2_500,
  browser: [viewport: {390, 844}, user_agent: "Cerberus Mobile Spec"]
)
|> visit("/live/counter")
|> assert_has(text("Count: 1"))
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
  webdriver_urls: [
    chrome: "http://127.0.0.1:4444",
    firefox: "http://127.0.0.1:5555"
  ]
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

Runtime launch settings (for example `show_browser`, `headless`, browser binaries, driver binaries, `webdriver_url`, and `webdriver_urls`) are runtime-level and should be configured globally per test invocation, not per test.

## Step 11: Cross-Browser Conformance Runs

```bash
mix test --only browser
```

`drivers: [:browser]` runs the default browser lane. For targeted multi-browser coverage, add explicit tags at module/describe/test scope:

```elixir
@moduletag drivers: [:browser]

describe "firefox-only flow" do
  @describetag drivers: [:firefox]
  test "..." do
  end
end

@tag drivers: [:chrome, :firefox]
test "run both browsers for this case only" do
end
```
