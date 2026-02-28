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
|> assert_has(text("Title loaded async"), timeout: 500)
```

> #### Tip
>
> Prefer timeout-bounded assertions for async LiveView states. Cerberus reacts to watched updates and still respects hard timeout budgets.
> You can also set defaults with `config :cerberus, :assert_timeout_ms, 300` and override per session via `session(assert_timeout_ms: ...)`.

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
