# Cheat Sheet

## Session and Driver Selection

| Goal | Call |
| --- | --- |
| Phoenix mode (auto static/live switching) | `session()` or `session(:phoenix)` |
| Real browser behavior | `session(:browser)` |
| Explicit browser lane | `session(:chrome)` or `session(:firefox)` |
| Live/browser assertion timeout default | `500ms` (override with `session(assert_timeout_ms: 300)`) |
| Browser ready timeout default | `session(:browser, ready_timeout_ms: 2200)` |
| Global headed mode | `config :cerberus, :browser, show_browser: true` |
| Global remote runtime | `config :cerberus, :browser, webdriver_url: "http://127.0.0.1:4444"` |
| Global screenshot defaults | `config :cerberus, :browser, screenshot_full_page: false, screenshot_artifact_dir: "tmp/screenshots"` |

## Core Navigation and Assertions

| Task | Example |
| --- | --- |
| Visit page | `visit(session, "/articles")` |
| Click link/button | `click(session, link("Counter"))` |
| Fill input | `fill_in(session, label("Search term"), "Aragorn")` |
| Select option | `select(session, label("Race"), option: "Elf")` |
| Choose radio | `choose(session, label("Email Choice"))` |
| Submit form | `submit(session, button("Run Search"))` |
| Assert text present | `assert_has(session, text("Articles", exact: true))` |
| Assert text absent | `refute_has(session, text("Error", exact: true))` |
| Assert path/query | `assert_path(session, "/search/results", query: %{q: "Aragorn"}, timeout: 500)` |
| Scope to subtree | `within(session, "#secondary-panel", fn s -> ... end)` |

## Multi-Session Operations

| Task | Example |
| --- | --- |
| New user (isolated state) | `session()` / `session(:browser)` |
| New tab (shared user state) | `open_tab(session)` |
| Switch active tab/session | `switch_tab(session, other_session)` |
| Close current tab | `close_tab(session)` |

## Locators

### Helper constructors
- `text("...")`
- `link("...")`
- `button("...")`
- `label("...")`
- `testid("...")`
- `css("...")`
- `role(:button, name: "...")`
- Composition: `button("Apply", has: testid("apply-secondary-marker"))`

### Supported role aliases
- Click/assert roles: `button`, `menuitem`, `tab`, `link`, `heading`, `img`
- Form-control roles: `textbox`, `searchbox`, `combobox`, `listbox`, `spinbutton`, `checkbox`, `radio`, `switch`

### Sigil `~l`

| Locator | Meaning |
| --- | --- |
| `~l"Save"` | text locator |
| `~l"Save"e` | exact text |
| `~l"button:Save"r` | role-style locator |
| `~l"button[type='submit']"c` | css locator |
| `~l"button:Save"re` | role + exact |

## Browser-Only Extensions

Use `Cerberus.Browser` only with `session(:browser)`.

| Task | Example |
| --- | --- |
| Screenshot | `Browser.screenshot(session, path: "tmp/page.png")` |
| Type keys | `Browser.type(session, "hello", selector: "#input")` |
| Press key | `Browser.press(session, "Enter", selector: "#input")` |
| Drag and drop | `Browser.drag(session, "#drag-source", "#drop-target")` |
| Dialog capture | `Browser.with_dialog(session, fn s -> click(s, button("Open Confirm Dialog")) end)` |
| Evaluate JS | `Browser.evaluate_js(session, "(() => 42)()")` |
| Evaluate JS with assertion callback | `Browser.evaluate_js(session, "(() => 42)()", fn value -> assert value == 42 end)` |
| Cookie lookup | `Browser.cookie(session, "_my_cookie")` |

> #### Warning
>
> Browser extension helpers intentionally raise on non-browser sessions to prevent silent semantic drift.

## Mode Switching Pattern

```diff
-session()
+session(:browser)
 |> visit("/articles")
 |> assert_has(text("Articles", exact: true))
```
