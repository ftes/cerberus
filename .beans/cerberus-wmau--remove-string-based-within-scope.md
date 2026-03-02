---
# cerberus-wmau
title: Remove string-based within scope
status: completed
type: task
priority: normal
created_at: 2026-03-02T11:20:23Z
updated_at: 2026-03-02T11:26:32Z
---

Drop within/3 CSS-string overload, require locator input only, and migrate tests/docs/examples to css(...) calls.

## TODO
- [x] Remove string-based `within/3` overload and raise explicit error for string scope input.
- [x] Keep locator-based `within/3` behavior intact (including live child-view optimization for `css("#id")`).
- [x] Migrate affected tests and docs/examples to `css(...)` locator calls.
- [x] Run format, targeted tests, and `mix precommit`.
- [x] Add summary and complete bean.

## Summary of Changes
- Removed CSS string support from `Cerberus.within/3`; passing a binary now raises `ArgumentError` instructing explicit `css("...")`.
- Preserved live nested-child ergonomics by retaining `find_live_child` switching for top-level `css("#child-id")` within scopes.
- Updated tests and docs to use locator input for `within/3` and added regression coverage for string-scope rejection.
- Verified with formatter, targeted test suite, and full precommit checks.
