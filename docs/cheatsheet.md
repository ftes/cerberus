# Cheat Sheet

## Session and Driver Selection

| Goal | Call |
| --- | --- |
| Phoenix mode (auto static/live switching) | `session()` or `session(:phoenix)` |
| Real browser behavior | `session(:browser)` |
| Public browser entrypoint | `session(:browser)` |
| Default project lane policy | Chrome-first (CI and regular local runs) |
| Unified default timeout | Static `0ms`, live/browser `500ms` |
| Per-session timeout override | `session(timeout_ms: 300)` or `session(:browser, timeout_ms: 300)` |
| Browser ready timeout default | `session(:browser, ready_timeout_ms: 2200)` |
| Per-driver timeout config | `config :cerberus, :live, timeout_ms: 700` |
| Global headed mode | `config :cerberus, :browser, headless: false` |
| Global slow motion | `config :cerberus, :browser, slow_mo: 120` |
| Global remote runtime | `config :cerberus, :browser, webdriver_url: "http://127.0.0.1:4444"` |
| Global screenshot defaults | `config :cerberus, :browser, screenshot_full_page: false, screenshot_artifact_dir: "tmp/screenshots"` |

## Core Navigation and Assertions

| Task | Example |
| --- | --- |
| Visit page | `visit(session, "/articles")` |
| Click link/button | `click(session, ~l"link:Counter"r)` |
| Fill input | `fill_in(session, ~l"Search term"l, "Aragorn")` |
| Select option | `select(session, ~l"Race"l, option: ~l"Elf"e)` |
| Choose radio | `choose(session, ~l"Email Choice"l)` |
| Check checkbox | `check(session, ~l"Accept Terms"l)` |
| Uncheck checkbox | `uncheck(session, ~l"Receive updates"l)` |
| Upload file | `upload(session, ~l"Avatar"l, "/tmp/avatar.jpg")` |
| Submit form | `submit(session, ~l"button:Run Search"r)` |
| Bypass browser actionability checks | `click(session, ~l"button:Hidden Action"r, force: true)` |
| Assert text present | `assert_has(session, ~l"Articles"e)` |
| Assert text absent | `refute_has(session, ~l"Error"e)` |
| Assert checked state | `assert_checked(session, ~l"Mail Choice"l)` |
| Refute checked state | `refute_checked(session, ~l"Email Choice"l)` |
| Assert disabled state | `assert_disabled(session, ~l"Disabled textaread"l)` |
| Refute disabled state | `refute_disabled(session, ~l"Notes"l)` |
| Assert readonly state | `assert_readonly(session, ~l"Readonly notes"l)` |
| Refute readonly state | `refute_readonly(session, ~l"Notes"l)` |
| Assert scoped text | `assert_has(session, ~l"#secondary-panel"c, ~l"Status: secondary"e)` |
| Refute scoped text | `refute_has(session, ~l"#secondary-panel"c, ~l"Status: primary"e)` |
| Assert path/query | `assert_path(session, "/search/results", query: %{q: "Aragorn"}, timeout: 500)` |
| Scope to subtree | `within(session, ~l"#secondary-panel"c, fn s -> ... end)` |

Actionability defaults:
- browser waits for matched controls to become enabled
- live retries briefly when a matched form control is still disabled after a LiveView update
- static fails immediately on disabled controls

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
| Fill a text input | label text | `fill_in(session, ~l"Email"l, "alice@example.com")` |
| Click a button | role + name | `click(session, ~l"button:Save"r)` |
| Click a link | role + name | `click(session, ~l"link:Billing"r)` |
| Assert rendered content | visible text | `assert_has(session, ~l"Settings saved"e)` |
| Operate inside repeated UI | scope + same locators | `within(session, ~l"#shipping-address"c, fn s -> fill_in(s, ~l"City"l, "Berlin") end)` |
| Disambiguate duplicate controls | `testid` | `click(session, ~l"apply-secondary-button"t)` |

### Supported role aliases
- Click/assert roles: `button`, `menuitem`, `tab`, `link`, `heading`, `img`
- Form-control roles: `textbox`, `searchbox`, `combobox`, `listbox`, `spinbutton`, `checkbox`, `radio`, `switch`

### Helper constructors
- `~l"..."e`
- `~l"..."l`
- `~l"..."t`
- `~l"..."c`
- `~l"button:..."r`

### Composition (advanced)
- scope chaining (descendant query): `~l"#actions"c |> scope(~l"button:Apply"r)`
- same-element AND intersection: `and_(~l"button:Apply"r, ~l"apply-secondary-button"t)`
- descendant requirement: `~l"button:Apply"r |> filter(has: ~l"apply-secondary-marker"t)`
- descendant exclusion: `~l"button:Apply"r |> filter(has_not: ~l"apply-secondary-marker"t)`
- visibility constraint: `~l"button:Apply"r |> filter(visible: true)`
- alternatives (OR): `or_(~l"#primary"c, ~l"#secondary"c)`
- boolean algebra: `and_(~l"button:Apply"r, not_(~l"apply-secondary-button"t))`
- negated conjunction: `not_(and_(~l"button:Apply"r, ~l"apply-secondary-button"t))`
- nearest ancestor scope: `closest(~l".fieldset"c, from: ~l"Email"le)`

### Sigil `~l`

| Locator | Meaning |
| --- | --- |
| `~l"Save"` | exact text (default) |
| `~l"Save"e` | exact text |
| `~l"Save"i` | inexact text |
| `~l"Email"l` | field label locator (`<label>`, `aria-labelledby`, or `aria-label`) |
| `~l"button:Save"r` | role-style locator |
| `~l"button[type='submit']"c` | css locator |
| `~l"save-button"t` | testid locator (`exact: true` default) |
| `~l"button:Save"re` | role + exact |

Rules:
- at most one kind modifier (`r`, `c`, `l`, or `t`)
- `e` and `i` are mutually exclusive
- `r` requires `ROLE:NAME`
- regex values are supported for text-like locators and role names, but cannot be combined with `exact: true|false`
- text-like matching normalizes whitespace by default (`normalize_ws: true`), including NBSP characters
- use `normalize_ws: false` to require exact raw whitespace matching

Use `~l"ROLE:NAME"r` for supported accessible-name matching on buttons, links, headings, and similar non-form elements.

## Browser-Only Extensions

Use `Cerberus.Browser` only with `session(:browser)`.

| Task | Example |
| --- | --- |
| Screenshot bytes | `png = Browser.screenshot(session, path: "tmp/page.png")` |
| Screenshot + keep piping | `Browser.with_screenshot(session, path: "tmp/page.png")` |
| Screenshot + open viewer | `Browser.with_screenshot(session, path: "tmp/page.png", open: true)` |
| Type keys | `Browser.type(session, ~l"#input"c, "hello")` |
| Press key | `Browser.press(session, ~l"#input"c, "Enter")` |
| Drag and drop | `Browser.drag(session, "#drag-source", "#drop-target")` |
| Popup capture | `session` \|> `Browser.with_popup(fn main -> click(main, ~l"button:Open Popup"r) end, fn _main, popup -> assert_path(popup, "/browser/popup/destination") end)` |
| Popup same-tab fallback | `session(:browser, browser: [popup_mode: :same_tab])` \|> `visit("/browser/popup/auto")` \|> `assert_path("/browser/popup/destination", timeout: 1500)` |
| Assert download (browser/static/live) | `session` \|> `click(~l"link:Download Report"r)` \|> `assert_download("report.txt")` |
| Evaluate JS (return result) | `value = Browser.evaluate_js(session, "(() => 42)()")` |
| Evaluate JS (pipe + callback) | `Browser.with_evaluate_js(session, "(() => 42)()", fn value -> assert value == 42 end)` |
| Cookie lookup | `Browser.cookie(session, "_my_cookie")` |
| Cookie callback | `Browser.cookie(session, "_my_cookie", fn cookie -> assert cookie end)` |
| Bulk cookie add | `Browser.add_cookies(session, [[name: "feature", value: "on"]])` |
| Clear cookies | `Browser.clear_cookies(session)` |
| Seed Phoenix session | `Browser.add_session_cookie(session, [value: %{user_id: user.id}], MyAppWeb.Endpoint.session_options())` |

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
