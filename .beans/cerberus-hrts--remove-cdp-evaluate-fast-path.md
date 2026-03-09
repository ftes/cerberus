---
# cerberus-hrts
title: Remove CDP evaluate fast path
status: completed
type: task
priority: normal
created_at: 2026-03-09T07:30:11Z
updated_at: 2026-03-09T07:51:21Z
---

## Scope

- [ ] Remove the optional Chrome CDP-backed browser evaluate fast path and related runtime/debugger-address plumbing.
- [ ] Keep browser execution on the BiDi path only with a clean cut.
- [ ] Remove the use_cdp_evaluate option from schemas, tests, and docs.
- [x] Re-run focused browser/runtime verification and document the reason for the cut.

## Notes

- Latest local conclusion: the CDP evaluate path does not make a meaningful enough difference in this repo to justify the extra browser-driver complexity.
- This should be a clean cut, not a compatibility shim or deprecated option.
- Remove only the narrow evaluate fast path; do not reintroduce broader CDP browser-driver work.

## Summary of Changes

Removed the narrow CDP-backed browser evaluate path with a clean cut. Deleted the `CdpPageProcess`, removed `use_cdp_evaluate` from option schemas and browser session types, stripped runtime debugger-address and browser-context CDP plumbing, removed the opt-in tests/docs, and returned browser evaluate execution to the BiDi-only path. Verified with `source .envrc && PORT=4878 MIX_ENV=test mix test test/cerberus/driver/browser/runtime_test.exs test/cerberus/browser_extensions_test.exs`.
