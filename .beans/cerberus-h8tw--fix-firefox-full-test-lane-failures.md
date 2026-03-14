---
# cerberus-h8tw
title: Fix Firefox full test lane failures
status: completed
type: bug
priority: normal
created_at: 2026-03-14T17:50:53Z
updated_at: 2026-03-14T18:21:56Z
---

Repair the full CERBERUS_BROWSER_NAME=firefox test lane after local reproduction showed 19 failures across runtime defaults, browser value assertions, download handling, readiness/session stability, and Firefox runtime integration cleanup. Verify with focused Firefox reruns and a full Firefox suite pass.

## Plan
- [x] Make browser readiness recovery tolerate dead browsing contexts during Firefox navigation timeouts
- [x] Normalize browser download filename matching for Firefox duplicate-name downloads
- [x] Remove Chrome-only assumptions from runtime tests and rerun focused Firefox suites
- [x] Re-run full CERBERUS_BROWSER_NAME=firefox suite and summarize any remaining failures

## Summary of Changes
- caught Firefox readiness `script.evaluate` timeouts as normal driver errors instead of letting them kill the browsing context, and made `last_readiness` reads safe when a context has already gone away
- normalized duplicate browser download filenames like `report(24).txt`, isolated browser extensions tests per session, and refreshed keyboard actions so Firefox runs stop leaking state across tests
- restarted the runtime explicitly in the Firefox runtime integration test so it always owns the fake Firefox process under mixed suites
- restored live-driver current-path resync for path assertions and preferred observed patch paths over stale LiveView proxy URLs so query-string patch assertions hold reliably
- widened the browser-only delayed value assertion timeout to stay stable under full-suite Firefox load
- verified `mix precommit`, `mix test`, and `CERBERUS_BROWSER_NAME=firefox mix test` all pass
