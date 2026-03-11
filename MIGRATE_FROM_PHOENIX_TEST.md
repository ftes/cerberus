# Migrate From PhoenixTest

This is not a full API reference. It is a short list of things that were unexpectedly important while migrating real PhoenixTest and PhoenixTest.Playwright tests.

The focus here is:
- what was easy to miss
- what was different from the old test style
- what would have saved time on a second migration pass

This intentionally ignores bugs that were fixed in Cerberus during migration and focuses on migration workflow and expectations.

## Start With The Right Split

Treat migrations as two different jobs:
- non-browser PhoenixTest tests
- browser PhoenixTest.Playwright tests

They may look similar in the old code, but the setup and failure modes are different enough that it is better to migrate them differently from the start.

## Non-Browser: Prefer `ConnCase` + `session(conn)`

For non-browser tests, the straightforward path was:

```elixir
use MyAppWeb.ConnCase, async: true

import Cerberus

conn = log_in_user(user)

conn
|> session()
|> visit(~p"/some/path")
|> assert_has(~l"Some text"e)
```

What helped:
- do not add browser sandbox `user_agent` wiring
- do not add browser helpers unless the test really is browser-backed
- keep using app-level conn login helpers for non-browser tests

If the test starts from a logged-in conn already, keep it that way.

## Browser: Do Not Try To Reuse Conn Login

The biggest practical difference was authentication.

For browser tests, logging in through the browser UI was the reliable migration path. Trying to reuse conn-based login patterns from non-browser tests was the wrong direction.

The useful shape was:

```elixir
use MyAppWeb.ConnCase, async: true

import Cerberus
import MyAppWeb.Cerberus

setup context do
  user = user_fixture()

  metadata = Cerberus.Browser.user_agent_for_sandbox(MyApp.Repo, context)

  session =
    session(:browser, user_agent: metadata)
    |> log_in(user)

  [session: session]
end
```

What helped:
- keep browser auth in a small support helper
- make that helper do UI login, not conn login
- pass real test `context` into browser sandbox metadata

One specific thing that would have saved time:
- if the browser lands on `/` after login, do not assume auth failed just because the next assertion or action fails
- in our migration, that often meant login had already succeeded and the real problem was post-navigation readiness or a dependent LiveView control that was not actionable yet

## Browser Sandbox Setup Is A Module Setup Concern

For browser modules using `ConnCase`, the test process already has SQL sandbox setup. The browser still needs metadata for websocket/browser access.

What would have helped to know upfront:
- non-browser tests do not need `user_agent`
- browser tests do need it
- the simplest pattern is to compute metadata from the test `context` and create the browser session from that
- this still works fine from `ConnCase, async: false`; the sandbox may already be checked out or shared for the test process, and Cerberus can reuse that owner state

Keep this in support code so the test body stays focused on behavior.

## Use Locator Sigils Early

Using sigils consistently made migrations easier:
- `~l"... "l` for label locators
- `~l"... "li` for inexact label locators
- `~l"... "r` for role locators
- `~l"... "e` for exact text
- `~l"... "i` for inexact text
- `~l"... "c` for CSS

This was easier to read and easier to review than mixing sigils and older string selectors.

If doing the migration again, I would switch to sigils immediately instead of partially converting and then normalizing later.

One easy thing to miss:
- `~l"... "li` is usually the right rewrite for old inexact label matching
- do not jump straight to regex labels unless the old test was really regex-shaped

Another migration surprise:
- PhoenixTest can target hidden modal submit buttons because it is not enforcing browser visibility semantics
- a Cerberus browser migration may need the real visible trigger first, or an intentional `force: true` if the old test was effectively interacting with hidden DOM

## Prefer Role/Label-Based Locators Over Old PhoenixTest Habits

Old PhoenixTest tests often leaned on:
- `click_button("Save")`
- `click_link("Timecards")`
- `assert_has(selector, text: "...")`

The Cerberus version was cleaner when rewritten directly to role/label locators instead of trying to preserve the old shape.

Examples:

```elixir
click(~l"button:Save"r)
click(~l"link:Timecards"r)
fill_in(~l"Email", "new@example.com")
```

This is especially important now that legacy link/button locator styles are gone.

Preserving structured locator semantics from PhoenixTest assertions also helped more than expected.

If the original assertion carried meaningful structure, keep it:
- keep CSS/class constraints when they narrow the right UI fragment
- keep role-based locators when the intent is really about a button/link/textbox
- keep field-container scoping when the assertion is about one labeled field, not page text in general

Flattening everything to plain text made failures harder to classify and usually produced worse debugging signal.

## Do Not Carry Over `text:` Assertion Style

PhoenixTest code often combined selector and text like:

```elixir
assert_has("#selector", text: "Main")
```

In Cerberus, it was usually better to rewrite the assertion intentionally rather than mechanically:

```elixir
assert_has(and_(~l"#selector"c, ~l"Main"e))
```

or, when text scoping was the real goal:

```elixir
within(~l"#selector"c, &assert_has(&1, ~l"Main"e))
```

That choice matters. Some migrations failed because the original PhoenixTest assertion was really relying on scoped text semantics, not just selector matching.

## Exact vs Inexact Text Matters More Than Expected

PhoenixTest assertions often read like exact text checks, but many of them are effectively substring checks in practice.

What helped:
- start with exact text when the UI text is stable and isolated
- switch to inexact text when asserting row content, labels inside larger cells, or content mixed with formatting

Example:

```elixir
assert_has(~l"Construction Assistant"i)
```

instead of assuming exact text will always match the rendered fragment.

## `within/3` Is Often The Right Rewrite

Several migrated assertions became clearer once rewritten as scoped assertions instead of compound selector guesses.

This was especially useful for:
- filters
- form fields
- selected-option assertions
- table fragments

If a PhoenixTest assertion was really saying “inside this section, assert X”, rewrite it that way directly.

This mattered for disabled field assertions too. In one EV2 case, the stable migration was not a plain field assertion but:
- scope to the labeled field container
- assert on the rendered input inside that container

That matched the original PhoenixTest intent better than treating it as a generic page-wide text or value assertion.

## Browser Tests Sometimes Need App-Specific Helpers

A small support module was worth it.

Useful helpers included:
- `log_in/2`
- `browser_session/1`
- `within_field/4`
- `assert_has_selected/4`

That kept migrated tests from filling up with repeated setup or field-container logic.

If migrating again, I would create the support module earlier instead of waiting for the second or third browser file.

## Browser JS Helpers Replace Some Playwright Frame APIs Cleanly

One migration surprise was that a few old Playwright tests were not really about Playwright itself. They were using frame-level JS evaluation for app checks like accessibility audits.

For Cerberus browser sessions, the practical replacement was usually `Browser.evaluate_js/2`.

Example migration shape:

```elixir
Browser.evaluate_js(session, A11yAudit.JS.axe_core())

results =
  session
  |> Browser.evaluate_js("(async () => JSON.stringify(await axe.run()))()")
  |> Jason.decode!()
  |> A11yAudit.Results.from_json()
```

What would have helped to know upfront:
- Cerberus can handle these browser-side checks without dropping back to Playwright APIs
- for this kind of audit, the result may be easiest to move through Cerberus as JSON text and decode in Elixir
- this is a good candidate for a small browser-support helper if more than one file needs it

## `assert_value` Is A Better Mental Model Than `assert_has(..., value: ...)`

PhoenixTest has patterns like asserting a field via `value: ...`.

In Cerberus, the clearer migration target was:

```elixir
assert_value(~l"New job title"l, "")
```

This maps better to browser semantics and avoids mixing text assertions with current input value checks.

If a migrated test is really about the current JS-visible field value, use `assert_value`, not `assert_has`.

One caveat from migration: `assert_value` was not always the right replacement for old `value:` assertions on disabled fields.

If the field is disabled or effectively read-only, a scoped rendered-input assertion may be a better match than `assert_value`.

## Dependent LiveView Controls Were A Repeated Migration Friction Point

A pattern that came up repeatedly in browser tests:
- select field A
- LiveView updates
- field B becomes enabled or repopulated
- next action on field B happens too early

What would have helped to know upfront:
- this is a common migration hotspot
- if an action fails because the target control is still disabled, the test may need an intermediate wait/assertion today
- that wait should be minimal and clearly about enabled state, not a broad custom sleep

Example shape:

```elixir
|> select(~l"Department", ~l"Production"e)
|> within_field("Job title", &assert_has(&1, ~l"select:not([disabled])"c))
|> select(~l"Job title", ~l"Rushes Runner"e)
```

This is not the ideal long-term browser API, but it is a useful migration technique when a dependent control becomes actionable asynchronously.

After the actionability work in Cerberus, I would now try the direct action first and only add the minimal enabled-state assertion if the remaining app/test case still truly needs it.

## Use Failure Shape To Classify The Problem

Several migration failures looked similar at first but had different causes.

What would have helped:
- `no ... matched locator` usually means locator rewrite or scoping is wrong
- `matched field is disabled` usually means a dependent control has not become actionable yet
- a failure immediately after browser login redirect does not necessarily mean login failed

That would have shortened a lot of debugging loops during migration.

Another useful split:

In practice, a destination-path assertion was often the better success signal for browser migrations.

Two more failure shapes were worth learning faster:
- if a modal is always present in the DOM but hidden by class/JS state, broad text assertions may match the wrong thing; scope to the visible modal container before clicking or refuting
- if a Cerberus copy keeps failing only on a cross-tab browser interaction, it may be a real browser-driver parity gap rather than a bad locator rewrite; don't burn the whole migration stream on one stubborn row

One small detail that cost time once: regex `assert_path` checks needed `exact: false` in that migration.

If the path visibly matches and the regex assertion still fails, try:

```elixir
assert_path(~r|/projects/\d+/contacts|, exact: false)
```

before assuming the navigation itself is wrong.

## Migrate Vertically, Not Mechanically

The most efficient migration style was:
- pick one file
- convert setup first
- convert the smallest passing slice
- run targeted tests
- then migrate the next tests in that file

Trying to do a broad syntax conversion first and only run later made it harder to tell whether a failure was:
- setup
- selector semantics
- browser readiness
- assertion semantics

Small vertical slices were much easier to debug.

## Tag Migrated Coverage Explicitly

It helped to tag migrated tests consistently, preferably at module or describe level where possible.

That made it easier to:
- rerun migrated slices
- compare Cerberus coverage against remaining PhoenixTest coverage
- track migration progress during partial conversion

## Practical Checklist

If doing another migration pass, I would follow this order:

1. Split browser and non-browser work.
2. For non-browser, use `ConnCase` and `session(conn)`.
3. For browser, set up a support helper with UI login and browser sandbox metadata from test `context`.
4. Rewrite selectors directly to sigil locators.
What helped in practice:
- prefer sigil locators over helper constructors when they express the same thing more directly
- for combined assertions, prefer `and_(~l"css"c, ~l"text"i)` over mixing sigils with `text(...)`
- PhoenixTest text assertions are inexact by default, so the closest rewrite is often `~l"... "i`, not exact text
- PhoenixTest `assert_has/refute_has(..., label: ...)` only applies the label constraint when paired with `value:`; if an original assertion uses `label:` without `value:`, inspect the rendered HTML and treat it as suspicious before migrating it literally
5. Rewrite `text:` assertions intentionally, often with `within/3`.
6. Use `assert_value` for actual field values.
7. Add tiny app-specific helpers early when patterns repeat.
8. Run small targeted slices with random `PORT=4xxx`.
9. Expect dependent LiveView controls to be a migration hotspot.
10. If a browser test lands on `/`, verify whether auth already succeeded before changing the login helper.

## What Would Have Saved The Most Time

If I had to do the migration again, the biggest time savers would have been:
- knowing upfront that browser auth should be via UI, not conn
- using a support `Cerberus` helper module from the start
- rewriting assertions semantically instead of mechanically preserving PhoenixTest shapes
- treating dependent disabled-to-enabled controls as a normal migration concern in browser tests
- using sigil locators consistently from the first edit
- using `~l"... "li` immediately for inexact label matches instead of reaching for regexes
- remembering that Cerberus `fill_in` takes the value positionally, not `with: ...`
- On some LiveView pages, rendered label text includes extra content or punctuation; use inexact text matching (`exact: false` or `~l"..."li`) rather than forcing exact label text.
- PhoenixTest workarounds that depend on wrapper internals (for example reading `active_form.form_data`) do not map directly to Cerberus `unwrap/2`; keep the low-level `render_change` path only where the page really needs JS.dispatch simulation.
