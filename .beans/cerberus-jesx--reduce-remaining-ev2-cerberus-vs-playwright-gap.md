---
# cerberus-jesx
title: Reduce remaining EV2 Cerberus vs Playwright gap
status: in-progress
type: task
priority: normal
created_at: 2026-03-08T09:18:04Z
updated_at: 2026-03-08T17:27:31Z
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
