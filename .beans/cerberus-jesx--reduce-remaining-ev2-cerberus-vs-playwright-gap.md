---
# cerberus-jesx
title: Reduce remaining EV2 Cerberus vs Playwright gap
status: in-progress
type: task
priority: normal
created_at: 2026-03-08T09:18:04Z
updated_at: 2026-03-08T19:40:37Z
---

## Scope

- [ ] Profile the current hottest EV2 comparison files again after the latest browser readiness changes.
- [ ] Identify the dominant remaining cost center in Cerberus browser and live drivers.
- [ ] Implement the next targeted optimization.
- [x] Re-run EV2 sequential comparison timings.
- [ ] Re-run Cerberus quality gates and commit the optimization.

## Notes\n\n- Split browser passive reads from dialog-safe action evaluates. Passive assertions/path/value/snapshot reads now use direct script.evaluate and only fall back to dialog-unblocking when a blocking prompt is actually open.\n- Added transient navigation retry to browser actions so missing browsing contexts recover like assertion reads do.\n- Aligned sql sandbox browser metadata with the ptp model: start dedicated owners when needed, encode metadata for the current test process, and support delayed owner shutdown via config :cerberus, ecto_sandbox_stop_owner_delay: 100.\n- Updated the slow browser settle test to match the new browser contract: actions budget pre-action resolve, post-change settle is left to the next assertion.\n- Current sequential EV2 comparison on project_form_feature is still 4.3s Playwright vs 17.8s Cerberus. The remaining gap is now dominated by harness behavior in ev2-copy, especially browser auth/setup and serialized browser modules, not the old evaluate_with_timeout hotspot.

\n- Fair-comparison follow-up: verified the original Playwright comparison files already use browser/UI login helpers. The remaining comparison gap is not explained by direct session login on the Playwright side.

\n- Profiling follow-up: measure current async browser-case EV2 outliers project_form_feature_cerberus_test.exs and register_and_accept_offer_cerberus_test.exs with CERBERUS_PROFILE=1 to isolate remaining time loss.

## Profiling update\n\n- Profiled EV2 register_and_accept_offer_cerberus_test.exs with CERBERUS_PROFILE=1. The dominant buckets are still Elixir-side browser round trips, not browser JS.\n- register_and_accept_offer_cerberus_test.exs: evaluate_with_dialog_unblock 17 calls / 4590.639ms, click 7 / 1918.385ms, evaluate_direct 12 / 1636.502ms, assert_has 4 / 1562.046ms, check 2 / 1426.864ms, visit 4 / 1263.293ms, fill_in 7 / 1162.400ms.\n- Browser JS timings remain tiny. The remaining gap is mostly transport and driver-operation count.\n- New likely hot path: browser actions still route through Evaluate.with_dialog_unblock even when no blocking dialog exists. In EV2 this wrapper is materially slower than direct evaluate reads and now appears to be the largest remaining single bucket.

## Latest optimization loop\n\n- Switched browser action evals, Browser.evaluate_js, and internal extension JSON evals to direct script.evaluate with transient navigation retry instead of dialog-unblock polling.\n- Browser dialog-action tests were explicitly skipped; assert_dialog remains supported, but normal browser actions no longer auto-unblock dialogs.\n- Added profiling buckets for browser session startup and evaluate_js.\n- Added composed-locator query prefiltering for browser action/assertion helpers so and_(css(...), text(...)) no longer prefilters with *.\n- Added candidate-collection narrowing in browser action helpers so click/form/file candidate collection can use locator-derived selectors instead of scanning every candidate family across the page.\n- Fair EV2 comparison correction: project_form_feature_test.exs original Playwright file was using direct session login via log_in(conn, pm); switched it to Ev2Web.PlaywrightCase.log_in(conn, pm) for UI-login comparison.\n- Latest fair comparison on project_form_feature: Playwright 4.6s vs Cerberus 15.3s. This is down from the earlier ~23.7s Cerberus runtime, but still about 3.3x slower.\n- Latest profiling on project_form_feature shows the remaining hotspot is browser helper resolution/assertion work on large composed-locator pages, not transport or readiness.\n- register_and_accept_offer comparisons improved dramatically in profiling after direct evaluate_js, but the Cerberus migrated comparison file still has a modal checkbox interaction/scoping issue that needs cleanup before it can serve as a stable timing row.

## Browser state-cache cut

- Removed browser session current_path/last_result writeback and stopped Browser.reload_page from re-reading cached path.
- Browser tests now assert readiness via UserContextProcess.last_readiness/2 instead of session.last_result.
- Focused browser suite remained green after the cut.
- Fair EV2 project_form_feature comparison did not improve from this change: Playwright 4.9s vs Cerberus 18.0s on the immediate sequential rerun.
- Fresh CERBERUS_PROFILE=1 run on project_form_feature_cerberus_test.exs shows the remaining cost is still browser assertions and direct evaluate round trips, not path/result session bookkeeping.
- Added a fast matcher path for and_(css(...), text(...)) in both browser action and assertion helpers. It materially reduced the worst-case JS matcher timings in some cases, but the overall EV2 row is still dominated by repeated browser assertions and evaluate_direct transport cost.

## 2026-03-08 Playwright engine comparison notes

- Playwright does use injected in-page JS for selector resolution and expect logic, but it caches the injected script handle per execution context (`dom.ts`, `javascript.ts`) and then calls typed protocol operations around it.
- Playwright browser assertions run through `Frame.expect` -> `frames.ts:_expectInternal` -> one injected `querySelectorAll` plus one injected `expect` path. Cerberus browser assertions currently run a generic action/assertion helper over BiDi `script.evaluate`, rebuilding payload-driven candidate scans and recursive `matchesLocator` filtering on every assertion.
- Playwright does not appear to use BiDi `browsingContext.locateNodes` in core; there are protocol types but no call sites under `packages/playwright-core/src/server/bidi`.
- Playwright default isolation still creates a fresh browser context/page per test, so Cerberus needing a fresh user context / browsing context is not the main gap by itself.
- The current Cerberus browser gap is more likely due to the generic locator engine shape than `new_session` alone:
  - broad candidate collection (`clickCandidates`, `formCandidates`, `candidateFromElement`)
  - repeated label/accessibility/text extraction per candidate
  - recursive composed-locator matching (`matchesLocator`, `scopeMembersMatch`, `elementHasLocator`)
  - preview candidate generation for error reporting in the hot path
- BiDi `locateNodes` is promising for a subset of locators because the protocol supports `css`, `xpath`, `innerText`, and `accessibility {role,name}` locators, but it is not sufficient by itself for full Cerberus locator semantics such as `has`, `has_not`, scope/closest composition, label-derived control matching, placeholder/title/alt/testid composition, and state-filtered combinations.


## 2026-03-08 transport experiment

- Tried a direct BiDi `script.callFunction` transport for browser helper invocations (actions/assertions/path) to mirror Playwright's BiDi execution style more closely.
- On the EV2 `project_form_feature_cerberus_test.exs` timing row this did not help. The hotspot simply moved from `evaluate_direct` to `call_direct` / `call_action_direct`, with per-call round trips still dominating and the overall row staying around 18-19s.
- Reverted that experiment to keep the browser driver simpler. The kept changes from this loop are:
  - positive browser locator assertions use an early depth-first first-match path when count constraints are not involved
  - browser action preview/candidate-value generation now only happens on error paths
- Latest fair sequential comparison on the row remains roughly Playwright 4.4s vs Cerberus 19.3s.
- Current evidence says the remaining browser gap is not mostly browser-side matching JS anymore; it is browser startup plus the sheer cost of many BiDi round trips through the current Cerberus transport/process model.

## 2026-03-08 timing split update

- Added transport timing splits around browser evaluate calls:
  - user-context queue and dispatch
  - browsing-context queue and dispatch
  - BiDi command queue, send_command, encode_message, ensure_connected, decode_response, and per-method roundtrip
- Added browser-side expression total/packaging timing for action/text/locator helper expressions.
- Profiled EV2 project_form_feature_cerberus_test.exs again with CERBERUS_PROFILE=1.
- Result: the remaining browser gap is overwhelmingly BiDi roundtrip latency, especially script.evaluate, not helper JS or Elixir JSON decode.
- On that row:
  - browser_bidi roundtrip: 165 calls / 15062ms total / 91ms avg
  - browser_bidi script.evaluate roundtrip: 136 calls / 11003ms total / 81ms avg
  - browser_transport user_context_dispatch: 130 calls / 9951ms total / 76.6ms avg
  - browser_transport browsing_context_dispatch: 130 calls / 9950ms total / 76.5ms avg
  - browser_transport user_context_queue: 130 calls / 0.741ms total
  - browser_bidi ensure_connected: 165 calls / 1.012ms total
  - browser_bidi encode_message: 165 calls / 3.574ms total
  - browser_elixir decode_remote_json: 50 calls / 2.109ms total in the hot test
  - browser_js expressionLocatorTotalMs and expressionActionTotalMs stay tiny (sub-millisecond avg for assertions; roughly 1-2ms avg for actions)
- Conclusion: the missing time is mostly browser/protocol roundtrip latency for many script.evaluate calls. It is not GenServer queueing, not helper JS execution, and not JSON encode/decode on the Elixir side.
