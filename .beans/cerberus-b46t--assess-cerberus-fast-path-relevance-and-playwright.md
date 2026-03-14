---
# cerberus-b46t
title: Assess Cerberus fast-path relevance and Playwright locator internals
status: in-progress
type: task
priority: normal
created_at: 2026-03-13T10:51:03Z
updated_at: 2026-03-13T17:15:52Z
---

Check whether the current parity benchmarks exercise Cerberus browser fast paths, and inspect local Playwright source/docs to understand how it waits and resolves locators more efficiently.\n\n- [ ] map benchmark scenarios to current Cerberus fast paths\n- [ ] inspect local Playwright source for waiting and locator resolution behavior\n- [ ] summarize whether removing fast paths is a useful experiment and how Playwright differs

## Notes

- [x] add benchmark concurrency support to Cerberus runner
- [x] add benchmark concurrency support to Playwright runner
- [x] smoke test concurrent churn runs on both runners
- [x] summarize whether the same harness works for both

\nConcurrent mode now runs N independent workers per round and reports round wall time plus per-flow mean. Cerberus uses N browser sessions; Playwright uses N isolated browser contexts/pages.

\nPost-fix note: removed browser within/3 usage from the benchmark flows and switched to direct phx-click/phx-value button locators. Also raised benchmark-only browser session timeout to 5000ms and per-worker round timeout to 120000ms so concurrency stress measures throughput instead of tripping default test-driver timeouts.

\nLatest benchmark run: with backoff-only polling, no MutationObserver, and non-count fast paths removed, the concurrency-14 matrix completed successfully across Cerberus and Playwright on both browsers.

\nFollow-up: assess whether non-browser action special-casing can be simplified and run the benchmark flow on the live/static path to see whether browser fast-path removals would analogously help or hurt there.



Live-driver benchmark probe now mounts as :live under ExUnit. Added a timeout override to the shared benchmark helper so the probe can measure heavy locator_stress flows instead of dying on the default 5000ms assertion timeout.



Started fixing the non-browser benchmark path. Added an internal candidate sentinel to avoid re-running already-satisfied CSS selectors on every live/static candidate, added a simple nested text fast path for has/has_not filters, and added live-driver parity tests for the benchmark fixture.



Added a single matrix runner script at bench/run_playwright_benchmark_matrix.exs. It runs the existing Cerberus and Playwright benchmark entrypoints sequentially and emits one combined CSV, with optional filters for runners, browsers, scenarios, and an output file path.



Validated the matrix runner with a small filtered run. It now forces MIX_ENV=test for child benchmark commands and successfully emits a combined CSV row set for Cerberus and Playwright.



Switched the live benchmark worker model back to true task concurrency. Each worker now starts its own Repo sandbox owner, encodes Phoenix sandbox metadata into the conn user-agent header, runs the live flow, and stops its owner in an after block.



Tried task-based live worker concurrency with per-worker sandbox owners and user-agent metadata. It still mounted as static because Phoenix.LiveViewTest fetches the ExUnit test supervisor from the current process and explicitly refuses child tasks. Reverted the live lane to the last working sequential version; true live concurrency needs ExUnit-managed worker processes, likely via parameterized tests or a similar shape.

Added a regular parity test for the shared playwright fixture assignment-modal path in test/cerberus/playwright_performance_benchmark_test.exs. It reproduces the current live-driver failure cleanly: browser passes, but the phoenix session never sees the Assignment queue dialog after clicking the target assignment button in locator_stress.

Fixed the live delayed-click path by waiting for post-click LiveView progress when the click produced no immediate diff, and added a focused assignment-modal parity test. The live playwright benchmark now runs cleanly again. Latest 3-iteration means at concurrency 1: live churn 984ms, live locator_stress 1457ms; Cerberus browser ranges 949-2099ms; Playwright ranges 1131-1811ms. This benchmark is now dominated by the fixtures built-in 535ms/615ms artificial delays, so it does not show a 10x live-vs-browser gap.

Follow-up: add a no-delay benchmark scenario because the current churn/locator_stress flows are dominated by fixture timers and can mask the true live-vs-browser overhead.


Normal mix test was still printing a live benchmark CSV row because the live benchmark worker lived under test/ and always registered ExUnit.after_suite. Moving that worker entrypoint under bench/ keeps the regular parity test in the suite while making benchmark reporting opt-in through the matrix runner.


After moving the live benchmark worker under bench/, simplified it again so the benchmark file always writes results and always prints its CSV row. The opt-in behavior now comes from path placement rather than extra env gating.


Added focused live profiling buckets around the post-action delayed progress wait and the underlying await_progress call so the churn_no_delay benchmark can show whether live click overhead is mostly waiting or something else.


Trying a narrower live wait heuristic: only keep the extra post-action progress wait when the returned rendered HTML matches the pre-action snapshot. If the action already produced an immediate rendered change, skip the hidden wait.


Added explicit server-side flow proof to the shared benchmark fixture and propagated it to the final done page. Both Cerberus and Playwright benchmark flows will now assert the exact proof trail and event count, so a suspiciously fast row cannot silently skip synchronization-heavy side effects.


The stricter proof trail changed the final done URL, which broke the Playwright benchmark because it was waiting for an exact URL string. Updated the Playwright harness to wait for required path/query params instead of exact query equality, matching Cerberus assert_path semantics more closely.


The first high-pressure benchmark pass with iterations=1,warmup=0,concurrency=14 failed in the live lane: one worker timed out waiting for the review dialog in churn. Investigating whether this is a live-driver sync issue or a benchmark harness artifact before using concurrency-14 as the baseline table.


Patched the live retry paths to anchor on session.render_version instead of a fresh current version. Retries now refresh immediately if the view is already ahead before falling back to await_progress, which should close the missed-diff race under concurrency.


Added a short chunked fallback on top of live progress waiting. Retries now wait in 100ms chunks, rechecking render_version between chunks, instead of one monolithic await_progress call that can miss already-completed diffs and then block until the full deadline.


The retry/backoff fallback reduced neither the review-modal failures nor the failure shape at concurrency 14. Next focus is the live button click path itself, since the failures consistently happen after the review-card click with no subsequent modal progress.


The selector-first live button path was initially shadowed by a duplicate metadata helper. Removed the dead duplicate so live button clicks now genuinely prefer Element.render_click/2 when a unique selector is available.


Tried preferring Element.render_click/2 for live buttons when a unique selector is available. It reduced concurrency-14 churn failures from 5 to 3 but did not fix the issue, so reverted it to keep the live button path simple.


Selector-first live button clicks were reverted. Next focus is LiveViewClient.await_progress/3 itself, since the remaining concurrency-14 churn failures still look like missed or delayed progress detection rather than locator or click-resolution work.


Added a root-proxy sync before LiveViewClient.html_tree/1 reads a live view tree. LiveViewTest already uses sync_with_root! in some DOM-read paths, and Cerberus had been reading the proxy tree without that synchronization.

## Sync check\n\n- Re-ran focused parity after the latest live-driver sync/refresh experiment: Running ExUnit with seed: 258363, max_cases: 28

.....
Finished in 10.3 seconds (0.00s async, 10.3s sync)
5 tests, 0 failures -> 5 tests, 0 failures.\n- Re-ran stressed live benchmark: Running ExUnit with seed: 410010, max_cases: 14

.............

  1) test live benchmark worker (Cerberus.LivePerformanceBenchmarkTest)
     Parameters: %{worker: 4}
     bench/live_performance_benchmark_test.exs:40
     assert_has failed: expected text not found
     locator: %Cerberus.Locator{kind: :css, value: "[role='dialog'][aria-label='Review candidate']", opts: [exact: true]}
     opts: [timeout: 20000, between: nil, max: nil, min: nil, count: nil, visible: true]
     current_path: "/phoenix_test/playwright/live/performance"
     scope: nil
     transition: %{reason: :click, from_path: "/phoenix_test/playwright/live/performance", from_driver: :live, to_driver: :live, to_path: "/phoenix_test/playwright/live/performance"}

     code: |> PlaywrightPerformanceBenchmark.run_cerberus_flow(@scenario, timeout_ms: 20_000)
     stacktrace:
       (cerberus 0.1.7) lib/cerberus/assertions.ex:362: Cerberus.Assertions.run_assertion!/6
       (cerberus 0.1.7) test/support/playwright_performance_benchmark.ex:97: Cerberus.TestSupport.PlaywrightPerformanceBenchmark.continue_flow/5
       bench/live_performance_benchmark_test.exs:45: (test)


Finished in 21.0 seconds (21.0s async, 0.00s sync)
14 tests, 1 failure
runner,browser,scenario,iterations,warmup,concurrency,mean_round_ms,mean_per_flow_ms,median_round_ms,p95_round_ms
live,phoenix,churn,1,0,14,2105.827,150.416,2105.827,2105.827 -> 14 tests, 5 failures.\n- Failures are unchanged in shape: review dialog never appears after the review button click, current_path stays .\n- Conclusion: the sync/refresh experiment did not materially help the live concurrency issue.


Latest live-driver note:

- Compared Cerberus live retry logic with PhoenixTest. PhoenixTest uses a much simpler fixed-interval retry wrapper around the real LiveViewTest action/assertion, plus redirect/death watcher handling; it does not drive retries from render-version inference.
- Simplified Cerberus live retry behavior toward that shape: keep navigation and render-version as hints, but let retries progress steadily with a carried attempt counter and backoff across the lifetime of one action/assertion.
- Also switched delayed no-diff live click settling onto the same retry helper.
- Focused live parity stayed green after the change.
- Re-ran the stressed live benchmark with concurrency 14: 14 tests, 0 failures, row `live,phoenix,churn,1,0,14,2205.550,157.539,2205.550,2205.550`.
- Conclusion: the benchmark flake was in the live retry/progress orchestration, and the simpler steady-backoff model is materially more robust under load.


Wrapper follow-up:

- Fixed `bench/run_playwright_benchmark_matrix.exs` to stream rows as they complete instead of buffering the entire matrix until the end.
- The wrapper now writes the CSV header immediately, appends each completed row to `--out`, and keeps partial results if a later row fails or the run is interrupted.
- Failure details now go to stderr and, when `--out` is used, to `<out>.failures.txt`.
- Verified with a cheap successful run and with an interrupted multi-row run: the output file preserved the completed rows written before termination.
