---
# cerberus-q0hy
title: Gate CDP browser evaluate behind session opt
status: completed
type: task
priority: normal
created_at: 2026-03-09T06:32:49Z
updated_at: 2026-03-09T07:07:29Z
---

## Scope

- [ ] Add a browser session opt to enable Chrome CDP-backed evaluate hot paths while keeping BiDi as the default browser transport.
- [ ] Thread the opt through session/browser config and the browser user-context evaluate path.
- [ ] Add focused tests for default BiDi behavior and opt-in CDP evaluate behavior.
- [x] Update browser docs/options and run focused browser verification.

## Notes

- Default must remain full BiDi.
- Opt-in should be session-scoped, not global-only.
- Prefer a clear name like use_cdp_evaluate over a typo-prone cdp_evalute.

## Summary of Changes

Reintroduced the narrow hybrid browser path: WebDriver BiDi remains the default browser transport, while `use_cdp_evaluate: true` opt-in sessions route browser evaluate hot paths through a Chrome CDP page websocket when a debugger address is available. Added the minimal `CdpPageProcess`, threaded runtime debugger-address and option resolution into browser user/browsing context setup, added focused runtime precedence and browser opt-in coverage, and documented the opt-in behavior. Verified with `source .envrc && PORT=4873 MIX_ENV=test mix test test/cerberus/driver/browser/runtime_test.exs test/cerberus/browser_extensions_test.exs`.
