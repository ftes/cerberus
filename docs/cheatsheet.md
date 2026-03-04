# Cheat Sheet

## Session and Driver Selection

| Goal | Call |
| --- | --- |
| Phoenix mode (auto static/live switching) | `session()` or `session(:phoenix)` |
| Real browser behavior | `session(:browser)` |
| Explicit browser lane | `session(:chrome)` or `session(:firefox)` |
| Default project lane policy | Chrome-first (CI and regular local runs) |
| Live/browser assertion timeout default | `500ms` (override with `session(assert_timeout_ms: 300)`) |
| Browser ready timeout default | `session(:browser, ready_timeout_ms: 2200)` |
| Global headed mode | `config :cerberus, :browser, headless: false` |
| Global slow motion | `config :cerberus, :browser, slow_mo: 120` |
| Global remote runtime | `config :cerberus, :browser, webdriver_url: "http://127.0.0.1:4444"` |
| Global screenshot defaults | `config :cerberus, :browser, screenshot_full_page: false, screenshot_artifact_dir: "tmp/screenshots"` |

## Core Navigation and Assertions

| Task | Example |
| --- | --- |
| Visit page | `visit(session, "/articles")` |
| Click link/button | `click(session, ~l"link:Counter"r)` |
| Fill input | `fill_in(session, label("Search term"), "Aragorn")` |
| Select option | `select(session, label("Race"), option: "Elf")` |
| Choose radio | `choose(session, label("Email Choice"))` |
| Check checkbox | `check(session, label("Accept Terms"))` |
| Uncheck checkbox | `uncheck(session, label("Receive updates"))` |
| Upload file | `upload(session, label("Avatar"), "/tmp/avatar.jpg")` |
| Submit form | `submit(session, ~l"button:Run Search"r)` |
| Assert text present | `assert_has(session, ~l"Articles"e)` |
| Assert text absent | `refute_has(session, ~l"Error"e)` |
| Assert scoped text | `assert_has(session, ~l"#secondary-panel"c, ~l"Status: secondary"e)` |
| Refute scoped text | `refute_has(session, ~l"#secondary-panel"c, ~l"Status: primary"e)` |
| Assert path/query | `assert_path(session, "/search/results", query: %{q: "Aragorn"}, timeout: 500)` |
| Scope to subtree | `within(session, ~l"#secondary-panel"c, fn s -> ... end)` |

Browser assertion execution model:
- `assert_has`/`refute_has` and path assertions use in-browser wait loops.
- Cerberus adds bounded transient eval retries for navigation/context-reset races.

## Multi-Session Operations

| Task | Example |
| --- | --- |
| New user (isolated state) | `session()` / `session(:browser)` |
| New tab (shared user state) | `open_tab(session)` |
| Switch active tab/session | `switch_tab(session, other_session)` |
| Close current tab | `close_tab(session)` |

## Locators

Default strategy:
- prefer user-facing locators first (label text, role + name, visible text)
- use `testid` when text is ambiguous or intentionally hidden
- use CSS as a last resort for structure-only targeting

### Common Phoenix/LiveView cases

| Goal | Preferred locator | Example |
| --- | --- | --- |
| Fill a text input | label text | `fill_in(session, label("Email"), "alice@example.com")` |
| Click a button | role + name | `click(session, ~l"button:Save"r)` |
| Click a link | role + name | `click(session, ~l"link:Billing"r)` |
| Assert rendered content | visible text | `assert_has(session, ~l"Settings saved"e)` |
| Operate inside repeated UI | scope + same locators | `within(session, ~l"#shipping-address"c, fn s -> fill_in(s, label("City"), "Berlin") end)` |
| Disambiguate duplicate controls | `testid` | `click(session, testid("apply-secondary-button"))` |

### Supported role aliases
- Click/assert roles: `button`, `menuitem`, `tab`, `link`, `heading`, `img`
- Form-control roles: `textbox`, `searchbox`, `combobox`, `listbox`, `spinbutton`, `checkbox`, `radio`, `switch`

### Helper constructors
- `text("...")`
- `link("...")`
- `button("...")`
- `label("...")`
- `aria_label("...")`
- `testid("...")`
- `css("...")`
- `role(:button, name: "...")`

### Composition (advanced)
- same-element AND: `button("Apply") |> testid("apply-secondary-button")`
- descendant requirement: `button("Apply") |> has(testid("apply-secondary-marker"))`
- descendant exclusion: `button("Apply") |> has_not(testid("apply-secondary-marker"))`
- alternatives (OR): `or_(css("#primary"), css("#secondary"))`
- boolean algebra: `and_(button("Apply"), not_(testid("apply-secondary-button")))`
- negated conjunction: `not_(and_(button("Apply"), testid("apply-secondary-button")))`
- nearest ancestor scope: `closest(css(".fieldset"), from: label("Email", exact: true))`

### Sigil `~l`

| Locator | Meaning |
| --- | --- |
| `~l"Save"e` | exact text |
| `~l"Save"i` | inexact text |
| `~l"button:Save"r` | role-style locator |
| `~l"button[type='submit']"c` | css locator |
| `~l"Run search"a` | aria-label locator |
| `~l"save-button"t` | testid locator (`exact: true` default) |
| `~l"button:Save"re` | role + exact |

Rules:
- at most one kind modifier (`r`, `c`, `a`, or `t`)
- `e` and `i` are mutually exclusive
- plain text `~l` locators require either `e` or `i`
- `r` requires `ROLE:NAME`

## Browser-Only Extensions

Use `Cerberus.Browser` only with `session(:browser)`.

| Task | Example |
| --- | --- |
| Screenshot | `Browser.screenshot(session, path: "tmp/page.png")` |
| Type keys | `Browser.type(session, "hello", selector: "#input")` |
| Press key | `Browser.press(session, "Enter", selector: "#input")` |
| Drag and drop | `Browser.drag(session, "#drag-source", "#drop-target")` |
| Dialog assert + dismiss | `Browser.assert_dialog(session, ~l"Delete item?"e)` |
| Dialog assert + confirm | `Browser.assert_dialog(session, ~l"Delete item?"e, accept: true)` |
| Popup capture | `session` \|> `Browser.with_popup(fn main -> click(main, ~l"button:Open Popup"r) end, fn _main, popup -> assert_path(popup, "/browser/popup/destination") end)` |
| Popup same-tab fallback | `session(:browser, browser: [popup_mode: :same_tab])` \|> `visit("/browser/popup/auto")` \|> `assert_path("/browser/popup/destination", timeout: 1500)` |
| Assert download (browser/static/live) | `session` \|> `click(~l"link:Download Report"r)` \|> `assert_download("report.txt")` |
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
 |> assert_has(~l"Articles"e)
```
