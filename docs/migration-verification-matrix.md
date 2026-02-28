# Migration Verification Matrix

This matrix defines the minimum PhoenixTest and PhoenixTestPlaywright API coverage for the
`cerberus-it5x` end-to-end migration verification loop.

Goal: prove that representative tests pass both before and after Igniter rewrites.

For execution flow and boundaries, see `docs/migration-verification.md`.

## Coverage Rules

- Each API family must be exercised at least once pre-migration and post-migration.
- Option coverage is representative (not combinatorial).
- Browser-only APIs are verified in browser lanes only.
- Matrix rows map to fixture scenarios that should be implemented in the nested fixture project.

## PhoenixTest Core Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| `visit/2` + session bootstrap | `conn |> visit`, `visit(conn, ...)` forms | `pt_static_nav` | route loads and expected text appears | rewritten session flow loads same route/text |
| `assert_has/2` | `visible: true`, `visible: :any`, `timeout:` | `pt_text_assert` | expected text found with same visibility semantics | same text semantics and timeout behavior |
| `refute_has/2` | `visible: true`, `visible: :any`, `timeout:` | `pt_text_refute` | absent text assertion passes | absent text assertion passes |
| `click/2` and click helpers | link vs button matching | `pt_click_navigation` | navigation + resulting path/text | same path/text transition |
| `fill_in/3` | label locator, selector narrowing | `pt_form_fill` | form value update visible in UI | same updated value |
| `check/2` and `uncheck/2` | checkbox arrays (`name[]`) | `pt_checkbox_array` | expected checked values in payload/UI | same payload ordering/values |
| `submit/2` | submit button ownership and form targeting | `pt_submit_action` | submit reaches expected destination | same destination and result text |
| `upload/3` | file input by label + path | `pt_upload` | uploaded filename/state visible | same uploaded filename/state |
| `assert_path/2` | `exact:`, `query:` subset | `pt_path_assert` | path and query expectations pass | same path/query semantics |
| `refute_path/2` | `exact:`, `query:` subset | `pt_path_refute` | mismatch expectations pass | mismatch expectations pass |
| `within/3` | nested scope selectors | `pt_scope_nested` | scoped assertions/actions limited to scope | same scope behavior |
| multi-user and multi-tab | `open_user`, `open_tab`, `switch_tab`, `close_tab` | `pt_multi_user_tab` | state isolation/sharing per contract | same isolation/sharing |

## LiveView-Specific Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| live click bindings | `phx-click`/JS command paths | `pt_live_click` | expected event-side effects | same side effects |
| live form change | dynamic inputs + `phx-change` ordering | `pt_live_change` | expected payload/order | same payload/order |
| live trigger action | `phx-trigger-action` edge transitions | `pt_live_trigger_action` | expected redirect/submit behavior | same redirect/submit behavior |
| live navigation | patch/navigate redirects | `pt_live_nav` | expected current path progression | same path progression |
| async live assertions | timeout-aware retries | `pt_live_async_timeout` | eventual state observed under timeout | same timeout semantics |

## PhoenixTestPlaywright Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| screenshot | default path + explicit path + full page | `ptpw_screenshot` | artifact exists with expected dimensions | artifact exists and operation metadata matches |
| keyboard typing | selector targeting + clear behavior | `ptpw_type` | expected input value and event effects | same value/effects |
| key press | `Enter` flow + active element targeting | `ptpw_press` | expected submit/result behavior | same submit/result behavior |
| dialog handling | callback flow + timeout + message match | `ptpw_dialog` | observed dialog accepted/cancelled state | same observed state/message checks |
| drag and drop | source/target selectors | `ptpw_drag` | target receives dropped value/state | same dropped value/state |
| cookies | `cookies`, `cookie`, `session_cookie`, `add_cookie` | `ptpw_cookies` | expected cookie visibility and fields | same cookie set/read behavior |
| JS evaluation | `evaluate_js` value roundtrip | `ptpw_eval_js` | expected expression result | same expression result |

## Scenario Completion Checklist

- [ ] Every matrix row has a concrete fixture test case.
- [ ] Every fixture test passes pre-migration in PhoenixTest/PhoenixTestPlaywright mode.
- [ ] Every fixture test passes post-migration in Cerberus mode.
- [x] CI report includes row-level pass/fail summary for before/after runs.

## Implemented So Far

These scenario ids are now exercised in the committed fixture and verified end-to-end in
`test/cerberus/migration_verification_test.exs`:

- `pt_static_nav`
- `pt_text_assert`
- `pt_text_refute`
- `pt_click_navigation`
- `pt_path_assert`
- `pt_path_refute`
- `pt_scope_nested`
- `pt_live_click`
