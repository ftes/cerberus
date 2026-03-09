---
# cerberus-hrts
title: Remove CDP evaluate fast path
status: todo
type: task
created_at: 2026-03-09T07:30:11Z
updated_at: 2026-03-09T07:30:11Z
---

## Scope

- [ ] Remove the optional Chrome CDP-backed browser evaluate fast path and related runtime/debugger-address plumbing.
- [ ] Keep browser execution on the BiDi path only with a clean cut.
- [ ] Remove the use_cdp_evaluate option from schemas, tests, and docs.
- [ ] Re-run focused browser/runtime verification and document the reason for the cut.

## Notes

- Latest local conclusion: the CDP evaluate path does not make a meaningful enough difference in this repo to justify the extra browser-driver complexity.
- This should be a clean cut, not a compatibility shim or deprecated option.
- Remove only the narrow evaluate fast path; do not reintroduce broader CDP browser-driver work.
