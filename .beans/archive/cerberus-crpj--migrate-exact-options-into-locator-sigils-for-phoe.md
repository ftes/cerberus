---
# cerberus-crpj
title: Migrate exact options into locator sigils for PhoenixTest ops
status: completed
type: bug
priority: normal
created_at: 2026-03-05T06:16:51Z
updated_at: 2026-03-05T06:24:06Z
---

Migration currently preserves exact: false options on rewritten action/assert calls, but Cerberus expects match semantics encoded in locators. Rewrite exact options into locator sigils and drop unsupported exact options for action/assert ops.


## Todo
- [x] Implement exact option canonicalization for migrated action and assertion ops
- [x] Add migration task tests for exact option rewrite/removal behavior
- [x] Run format and targeted migration tests
- [x] Run precommit plus full and slow test suites
- [x] Summarize changes and mark completed

## Summary of Changes

- Added migration canonicalization for exact options on action and assertion operations so unsupported exact options are removed from rewritten Cerberus call options.
- Encoded migrated exact matching semantics directly into locator expressions by rewriting text sigils and text locator calls.
- Implemented operation family mapping: action op exact values are flipped into locator exactness, while assertion op exact values map directly to locator exactness.
- Added coverage for choose exact option rewrites and assert_has/refute_has exact option rewrites, including removing trailing exact options.
- Verified with mix precommit, full mix test, and mix test only slow.
