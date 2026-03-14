---
# cerberus-qas4
title: Rewrite locator resolvers around selector-first semantics
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T08:26:35Z
updated_at: 2026-03-14T18:38:33Z
---

Rewrite browser and LazyHTML locator resolution from scratch around a selector-first, narrow-resolution model guided by Playwright. Start by removing the temporary live label fast path, then rebuild static and live resolution, broaden browser coverage carefully, and enable parity tests incrementally while keeping complexity minimal.


## Notes

- rewrote shared LazyHTML form-field resolution around selector-first explicit-label, implicit-label, and attr-specific queries instead of the older generic candidate matcher
- rewrote shared link and button resolution to query narrowed selectors first and build matches directly, keeping the recursive generic matcher only where locator composition still needs it
- rewrote shared submit-button resolution to query submit-capable controls directly and derive owner-form metadata from the matched node instead of scanning forms and owner-form branches separately
- preserved EV2 live notifications row improved from roughly 14s before this rewrite series to 9.8s on the latest warm Cerberus rerun, versus 2.4s for the restored PhoenixTest baseline
- browser resolver rewrite is still pending; this slice only covered shared LazyHTML resolution used by static and live

## Notes
- kept role locator semantics broad for now (matching accessible-name source variants) after a stricter single-name rewrite broke existing static/live parity coverage
- selector-first shared button resolution stays in place; the major win in this slice came from avoiding unconditional state projection during matching

## Notes
- browser locator assertions now mirror the shared count-first, diagnostics-on-failure algorithm used by static/live
- preserved EV2 browser row project_form_feature_cerberus_test stayed about 16.7s after this slice, so browser resolver JS is no longer the dominant gap there
- profile on the preserved browser row shows the remaining hotspot is still script.evaluate transport roundtrip and evaluate_direct/evaluate_action_direct volume, not locator matching time

## Notes
- added a cheap one-round matcher contract harness that now covers 43 shared HTML/Node DOM cases across assertion and action resolution, including benchmark-style has/has_not filters, closest(from:), count/refute count constraints, or_/not_ composition, submit nested filters, and action ambiguity failures
- expanded the focused contract test to lock those normalized results in place and kept the cross-lane runner green
- normalized range-based between count filters in Cerberus.Query so the low-level round resolvers accept the same tuple and range shapes as the higher-level APIs

## Notes
- expanded the one-round matcher contract to cover count-position action selection for click/fill_in/submit, wrapped-label and aria-labelledby field matching, multiple-label field association, and the submit nested or_ inside has ambiguity case
- added immediate actionability/state matching coverage for disabled and readonly action filters in the shared HTML/Node DOM harness
- the new repeated-card action locator case currently documents a real gap: button action locators with nested has/has_not filters still resolve to no match in both lanes

## Notes
- fixed the button-role matcher confusion in the new contract cases by aligning role-name exactness with real accessible-name semantics; click action locators with role + has/has_not now resolve correctly when the role name is intentionally non-exact
- expanded the shared contract to cover wrapped labels, aria-labelledby, multi-label fields, count-position action selection across click/fill_in/submit, and the repeated-card one-shot action locator
- migration status: the new round resolver/payload structure is in place for the cheap harness and shared HTML APIs, but the browser and driver runtimes still layer their polling/action execution logic on top of those matchers rather than fully dispatching through the round APIs

## Notes
- ran a cheap live-only locator_stress experiment with PhoenixTest-style concrete selectors under the same 1/0/14 shape; it came back at roughly 8319ms round versus about 8054ms for the current Cerberus live row, so simpler selectors alone do not explain the PhoenixTest gap
- this points the remaining live locator_stress cost at shared live/session retry or assertion orchestration rather than just nested has/has_not locator resolution

## Notes
- added opt-in benchmark step tracing for the Cerberus live and PhoenixTest benchmark flows plus a small summarizer script; traced locator_stress at 1/0/14 shows the largest gaps are not candidate-search setup or simple assertions but post-action live steps
- in the clean traced run, Cerberus live versus PhoenixTest means were roughly: open_assignment_modal 1711ms vs 770ms, choose_assignment 1823ms vs 610ms, apply_filters 1238ms vs 266ms, continue_workflow 1044ms vs 177ms, assert_target_card 596ms vs 138ms, await_patched_state 614ms vs 298ms; this points the remaining performance gap more at live action/assertion orchestration after clicks than at simple locator parsing alone

## Notes
- tried removing the eager post-click delayed-progress settle for ordinary live button clicks to make Cerberus live more PhoenixTest-like; focused parity stayed green and the full suite still passed, but live benchmark results regressed and churn_no_delay re-exposed the live_redirect benchmark failure, so the change was reverted
- benchmark impact from the attempted click-settle removal was roughly: live churn 2505ms, live churn_no_delay 1421ms with a benchmark failure, live locator_stress 10922ms, phoenix_test churn 1685ms, phoenix_test churn_no_delay 1377ms, phoenix_test locator_stress 3775ms

## Notes
- refactored the new shared round-match helpers to clear Credo and Dialyzer, including removing dead browser assertion-payload visibility fallback and normalizing round-result helpers
- verified the new Node/JSDOM round-contract runner locally after npm ci and wired GitHub Actions CI to install Node 24 plus npm deps before running mix run bench/run_match_round_contract.exs
- documented the JS contract runner in docs/browser-tests.md so local setup matches CI expectations

## Notes
- verified the stable tree again after reverting the lazy-refresh experiments: full suite passed at 631 tests, 0 failures, and the live vs phoenix_test locator_stress benchmark at 1/0/14 was about 8274ms vs 3497ms
- tried two versions of PhoenixTest-style lazy live click refresh that kept tree snapshots stale until the next operation; both looked promising on raw round time at moments, but both broke the concurrent locator_stress patch/assert_path step because pending live patch state was not integrated robustly enough, so both experiments were reverted
- takeaway: the next viable direction is a more explicit separation of stale DOM state versus pending patch/navigation state, rather than a partial lazy-refresh shortcut bolted onto the current session model

## Notes
- ran a cheap benchmark-only PhoenixTest-style live-session experiment behind an env flag that stopped eagerly refreshing the live document after successful actions and instead tried to refresh on the next DOM-dependent operation
- after fixing two compatibility gaps that the experiment surfaced (trigger-action scanning on nil documents and within/3 requiring a materialized document), the focused live slice passed, but the benchmark regressed badly at 1/0/14 versus the stable baseline
- control rows were: live churn 2530.396ms, live churn_no_delay 1440.684ms, live locator_stress 8947.378ms, phoenix_test churn 1591.786ms, phoenix_test churn_no_delay 1429.295ms, phoenix_test locator_stress 3907.318ms
- experimental rows were: live churn 2534.743ms, live churn_no_delay 2211.771ms, live locator_stress 11903.356ms, phoenix_test churn 1705.456ms, phoenix_test churn_no_delay 1589.332ms, phoenix_test locator_stress 3904.882ms
- conclusion: copying PhoenixTest laziness onto the current Cerberus live session model is not enough and currently makes throughput worse; the remaining gap is more likely in the retry/assertion orchestration and session-state shape than in the mere fact that Cerberus refreshes its live tree eagerly

## Notes
- compared EV2 non-browser original vs Cerberus pairs under the same warm local shape using max-cases 1 and the existing google-chrome-stable shim on PATH so test helper booted cleanly
- export_live pair was effectively tied: original 1.5s ExUnit / 3.78s wall for 10 tests, Cerberus 1.4s ExUnit / 3.51s wall for 10 tests
- project_settings_live notifications was materially slower under Cerberus but not catastrophic: original 2.5s ExUnit / 4.57s wall for 18 tests, Cerberus 4.3s ExUnit / 6.59s wall for 18 tests, about 1.7x slower on test runtime
- offer_live offer_new showed a similar moderate gap: original 2.9s ExUnit / 6.01s wall for 14 tests, Cerberus 4.0s ExUnit / 6.77s wall for 14 tests, about 1.4x slower on test runtime
- takeaway from EV2 non-browser so far: Cerberus live/static is not at parity, but it is close enough on simple pages and only moderately slower on heavier LiveViews; that makes further deep live-model work look lower ROI than browser work unless a specific EV2 non-browser flow becomes a top complaint

## Notes
- added Cerberus reproducing coverage for live current_path patch handling in test/cerberus/current_path_test.exs, including EV2-style phx-change push_patch query/select flows plus low-level LiveViewClient patch-emission checks
- the actual fix was in the live driver, not the proxy: after successful live click/fill_in/submit results, Cerberus now gives delayed navigation a slightly wider 500ms settle window when the current_path is still unchanged, which lets late patch messages update session.current_path without reviving the earlier broken assert_path sync experiment
- verification in Cerberus: current_path_test plus path_scope_behavior_test and live_click_bindings_behavior_test are green, and the full Cerberus suite passed at 637 tests, 0 failures, 2 skipped
- verification in EV2: the previously failing non-browser path regressions now pass directly in test/ev2_web/admin/pages/queries_live/index_cerberus_test.exs and test/ev2_web/live/calendar_live/index_cerberus_test.exs under max-cases 1
- rerunning the full EV2 compare.copy lane no longer points at those live/path failures; the first remaining visible failure is back in the browser lane (generate_timecards_browser_cerberus_test readiness timeout), while the overall alias still behaves like a long/noisy suite that can sit for a long time after surfacing failures

## Notes
- added a browser-side reproducer by flipping the existing busy-live-root readiness case in test/cerberus/browser_action_settle_behavior_test.exs: ongoing mutation churn under a connected live root should no longer block browser visit readiness forever
- fixed the browser readiness watcher in lib/cerberus/driver/browser/browsing_context_process.ex so once a live page is connected and a quiet timer is already armed, repeated dom-mutation events no longer keep restarting the settle window; disconnected-to-connected transitions still arm readiness correctly
- verification in Cerberus: browser_action_settle_behavior_test, browser_timeout_assertions_test, browser_test, and the full Cerberus suite all passed after the change (637 tests, 0 failures, 2 skipped)
- verification in EV2: the previously failing generate_timecards_browser_cerberus_test file now passes directly under max-cases 1; rerunning the full compare.copy alias no longer fails quickly on the old browser readiness timeout and instead returns to the longer slow/noisy suite behavior
