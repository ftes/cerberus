---
# cerberus-y6gj
title: Refactor browser driver to shared BiDi runtime + userContext/browsingContext supervision
status: completed
type: task
priority: normal
created_at: 2026-02-27T09:50:55Z
updated_at: 2026-02-27T10:34:57Z
parent: cerberus-sfku
---

## Scope
Refactor browser driver internals to match the decided architecture:
- one shared WebDriver runtime process
- one shared BiDi connection process
- one userContext process per test
- one browsingContext process per tab/window

## Technical Steps
- [x] document supervision tree, strategy, and restart behavior in docs.
- [x] replace per-session runtime model with shared runtime + BiDi server.
- [x] add UserContext supervisor/process and BrowsingContext supervisor/process.
- [x] adapt browser driver entry points (new_session/visit/click/assert/refute) to new process model.
- [x] update/extend tests via integration coverage (explicit supervision unit tests intentionally skipped by decision).

## Done When
- [x] browser driver architecture matches the decision tree.
- [x] tests pass for non-browser/unit surfaces; browser tests remain runnable when runtime is available.

## Notes (2026-02-27)
- Copied architecture decisions into module docs for discoverability:
  - ADR-0001 in Cerberus, Cerberus.Driver, and Cerberus.Query.
  - ADR-0002 in Cerberus.
  - ADR-0003 in Cerberus.Harness.
  - ADR-0004 and BiDi-vs-CDP direction in Cerberus.Driver.Browser.

- Reverted Runtime HTTP transport experiment: restored :httpc path for WebDriver /status, /session, and /session/{id} calls; removed raw TCP request/response code.

- Fixed HTTP runtime dependency loading by adding inets/ssl to Mix extra_applications; :http_util is now available and WebDriver session handshake proceeds via :httpc.
- After this fix, test failures dropped from 7 (HTTP transport startup failure) to 2 (browser live interaction parity).

- Added fixture browser bootstrap source at assets/js/app.js and static output at priv/static/assets/app.js.
- Added mix assets.build task (Mix.Tasks.Assets.Build) to sync assets/js/app.js into priv/static/assets/app.js without introducing a bundler.
- Updated fixture endpoint/layout to serve and load phoenix.min.js, phoenix_live_view.min.js, and /assets/app.js for browser LiveView tests.
- Test endpoint port is configured via PORT (default 4101), so runs can isolate with PORT=400x mix test.
- Verified with repeated targeted runs and full suite: mix test --seed 0 passes (20 tests).

- Normalized expected owner-driven userContext teardown: UserContextProcess now stops with :normal when the owner test process exits, removing noisy :owner_down error reports while keeping cleanup semantics unchanged.
- Verified after change: mix test --seed 0 => 20 tests, 0 failures.

- Browser test verification from Codex is currently unreliable under workspace sandbox (Chrome fails to launch with session not created / instance exited), while the same tests can run from user shell. Treat browser pass/fail as user-shell authoritative for now.

## Summary of Changes
- Implemented the shared BiDi browser driver architecture: single Runtime, single BiDi connection, userContext-per-test, browsingContext-per-tab.
- Documented the supervision tree, restart strategy, and BiDi terminology decisions in module docs.
- Reverted raw TCP HTTP experiment and restored `:httpc` runtime calls with `:inets`/`:ssl` startup dependencies.
- Fixed browser/live parity by wiring fixture LiveView bootstrap through `/assets/app.js` and static script serving.
- Added `mix assets.build` to sync `assets/js/app.js` into `priv/static/assets/app.js`.
- Added test port override support via `PORT` (default `4101`) for parallel test runs on distinct ports.
- Normalized owner teardown logging by treating owner-down shutdown as `:normal` in `UserContextProcess`.
- Verified with repeated targeted runs and full suite (`mix test --seed 0`): 20 tests, 0 failures.

- Fixed ChromeDriver version-selection behavior in test boot: test_helper now chooses a driver whose major version matches the selected Chrome binary, instead of picking the lexicographically latest cached driver.

- Updated bin/check_bidi_ready.sh to prefer a locally cached matching ChromeDriver under tmp/browser-tools before PATH chromedriver; this removes false major-mismatch failures when PATH points to a different major.
