---
# cerberus-7r94
title: Provision Firefox runtime and execute full conformance matrix
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:36:48Z
updated_at: 2026-02-28T08:40:20Z
parent: cerberus-ykr0
---

Install/pin Firefox + GeckoDriver in the test/CI environment and run the browser conformance suites with browser_matrix [:chrome, :firefox]. Capture any browser-specific mismatches and triage follow-up fixes.

## Summary of Changes

- Provisioned local Firefox + GeckoDriver runtime (`/Applications/Firefox.app/Contents/MacOS/firefox`, `geckodriver 0.36.0`) and verified BiDi `webSocketUrl` session handshake.
- Updated test runtime config to support browser matrix execution via `CERBERUS_BROWSER_MATRIX` and optional Firefox/GeckoDriver env vars.
- Added docs for matrix execution and Firefox runtime requirements (README + getting-started + browser support policy).
- Executed cross-browser conformance run with matrix expansion:
  - command: `CERBERUS_BROWSER_MATRIX=chrome,firefox mix test --only conformance --only browser`
  - result: `106 tests, 0 failures (115 excluded)`.
- Validated full quality gate with `mix precommit` under Chrome + Firefox environment variables.
