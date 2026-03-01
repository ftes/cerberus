# Migration Verification Matrix

This matrix defines the minimum PhoenixTest and PhoenixTestPlaywright API coverage for the
`cerberus-it5x` end-to-end migration verification loop.

Goal: prove that representative tests pass both before and after Igniter rewrites.

For execution flow and boundaries, see `docs/migration-verification.md`.

## Coverage Rules

- Each row maps to a **source** PhoenixTest/PhoenixTestPlaywright API family.
- Each API family must be exercised at least once pre-migration and post-migration.
- Option coverage is representative (not combinatorial).
- Rows should be behavior-distinct (no duplicated call chains with only assertion wording changes).
- Browser-only source APIs are verified in browser lanes only.
- Matrix rows map to fixture scenarios that should be implemented in the nested fixture project.

## PhoenixTest Core Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| `visit/2` + session bootstrap | `conn |> visit`, `visit(conn, ...)` forms | `pt_static_nav` | route loads and expected text appears | rewritten session flow loads same route/text |
| `assert_has/3` | `text:`, `value:`, `count:`, `at:`, `timeout:` | `pt_text_assert` | expected selector+content assertions pass | same selector+content and timeout semantics |
| `refute_has/3` | `text:`, `value:`, `count:`, `at:`, `timeout:` | `pt_text_refute` | mismatch/absence assertions pass | same mismatch/absence semantics |
| `click/2` and click helpers | link vs button matching | `pt_click_navigation` | navigation + resulting path/text | same path/text transition |
| `fill_in/3` + `fill_in/4` | label exact/non-exact matching, selector narrowing | `pt_form_fill` | targeted form field receives expected value | same targeted value behavior |
| `select/3` and `select/4` | label + option matching, exact option semantics | `pt_select` | selected option included in resulting payload/UI | same selected option semantics |
| `choose/3` and `choose/4` | radio label targeting and checked-value submission | `pt_choose` | chosen radio value included in payload/UI | same chosen value semantics |
| `check/2` and `uncheck/2` | checkbox arrays (`name[]`) | `pt_checkbox_array` | expected checked values in payload/UI | same payload ordering/values |
| `submit/1` | active-form submit, submit-button name/value inclusion | `pt_submit_action` | submit reaches expected destination with expected payload | same destination and payload semantics |
| `upload/3` | file input by label + path | `pt_upload` | uploaded filename/state visible | same uploaded filename/state semantics |
| `assert_path/2` and `assert_path/3` | wildcard paths + `query_params:` subset + `timeout:` | `pt_path_assert` | path/query expectations pass | same path/query+timeout semantics |
| `refute_path/2` and `refute_path/3` | wildcard paths + `query_params:` subset + `timeout:` | `pt_path_refute` | mismatch expectations pass | same mismatch+timeout semantics |
| `within/3` | nested scope selectors | `pt_scope_nested` | scoped assertions/actions limited to scope | same scope behavior |
| `unwrap/2` | static `conn` callback + live `view` callback | `pt_unwrap` | callback return values continue pipeline correctly | same continuation/redirect semantics |

## LiveView-Specific Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| live click bindings | `phx-click`/JS command paths | `pt_live_click` | expected event-side effects | same side effects |
| live form change | dynamic inputs + `phx-change` ordering | `pt_live_change` | expected payload/order | same payload/order |
| live navigation | patch then navigate/redirect progression | `pt_live_nav` | expected path transition sequence | same transition sequence |
| async live assertions | `assert_has/refute_has` timeout retries for eventual UI | `pt_live_async_timeout` | eventual state observed under timeout | same timeout/retry semantics |

## PhoenixTestPlaywright Matrix

| Source API family | Representative options | Fixture scenario id | Pre-migration assertion | Post-migration assertion |
| --- | --- | --- | --- | --- |
| screenshot | default path + explicit path + full page | `ptpw_screenshot` | artifact exists with expected dimensions | blocked until `cerberus-55qd` (browser migration lane support) |
| keyboard typing | selector targeting + clear behavior | `ptpw_type` | expected input value and event effects | blocked until `cerberus-55qd` (browser migration lane support) |
| key press | `Enter` flow + active element targeting | `ptpw_press` | expected submit/result behavior | blocked until `cerberus-55qd` (browser migration lane support) |
| dialog handling | callback flow + timeout + message match | `ptpw_dialog` | observed dialog accepted/cancelled state | blocked until `cerberus-55qd` (browser migration lane support) |
| drag and drop | source/target selectors | `ptpw_drag` | target receives dropped value/state | blocked until `cerberus-55qd` (browser migration lane support) |
| cookie setup | `add_cookies/2`, `add_session_cookie/3`, `clear_cookies/1` | `ptpw_cookies` | expected cookie mutation effects in browser/session | blocked until `cerberus-55qd` (browser migration lane support) |
| JS evaluation | `evaluate/2` and decoder callback variants | `ptpw_eval_js` | expected expression result | blocked until `cerberus-55qd` (browser migration lane support) |
| Playwright unwrap | `unwrap/2` native page/frame callback | `ptpw_unwrap` | native callback result can drive flow continuation | blocked until `cerberus-55qd` (browser migration lane support) |

## Source API Gaps (Manual Migration)

These source APIs exist but currently do not have first-class migration parity rows.

| Source API family | Current status |
| --- | --- |
| PhoenixTest.Playwright migration rows | blocked by `cerberus-55qd` until browser migration lane support lands |
| `open_browser/1` | debug helper; intentionally excluded from parity matrix |

## Blocked Matrix Rows

These rows are defined but currently blocked on missing Cerberus implementation work.

| Fixture scenario id | Blocker |
| --- | --- |
| `ptpw_screenshot` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_type` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_press` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_dialog` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_drag` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_cookies` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_eval_js` | blocked by `cerberus-55qd` (browser migration lane support) |
| `ptpw_unwrap` | blocked by `cerberus-55qd` (browser migration lane support) |

## Scenario Completion Checklist

- [ ] Every matrix row has a concrete fixture test case.
- [ ] Every fixture test passes pre-migration in PhoenixTest/PhoenixTestPlaywright mode.
- [ ] Every fixture test passes post-migration in Cerberus mode.
- [x] CI suite asserts successful pre/post full-pattern runs (`mix test` exit status `0` before and after rewrite).

## Implemented So Far

These scenario ids are now exercised in the committed fixture and verified end-to-end in
`test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs`:

- `pt_static_nav`
- `pt_text_assert`
- `pt_text_refute`
- `pt_click_navigation`
- `pt_form_fill`
- `pt_select`
- `pt_choose`
- `pt_checkbox_array`
- `pt_submit_action`
- `pt_upload`
- `pt_path_assert`
- `pt_path_refute`
- `pt_scope_nested`
- `pt_unwrap`
- `pt_live_click`
- `pt_live_change`
- `pt_live_nav`
- `pt_live_async_timeout`
- `pt_multi_user_tab`
