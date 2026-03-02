---
# cerberus-uqjm
title: Support assert_has/refute_has scoped string shorthand
status: completed
type: feature
priority: normal
created_at: 2026-03-02T12:03:17Z
updated_at: 2026-03-02T12:05:36Z
---

Treat scoped assert/refute arg3 binary/regex as text shorthand, clarify scope arg naming/docs, and make scoped text shorthand the default docs example.

## TODO
- [x] Clarify `assert_has/refute_has` API docs and naming for scoped-vs-unscoped overload behavior.
- [x] Make scoped string shorthand examples first-class in user docs.
- [x] Add regression coverage for scoped binary/regex arg-3 shorthand.
- [x] Run format, targeted tests, and precommit.
- [x] Add summary and complete bean.

## Summary of Changes
- Added public `@doc` guidance for `assert_has/refute_has`, including scoped examples that use binary arg-3 text shorthand.
- Renamed internal overload variables from `scope_or_locator` to clearer `locator_or_scope_locator`.
- Added scoped string-shorthand examples to README/getting-started/cheatsheet.
- Added conformance coverage in `path_scope_behavior_test` for scoped binary/regex arg-3 shorthand.
- Verified with formatting, targeted tests, and precommit.
