---
# cerberus-300e
title: Make label-string examples consistent for form actions
status: completed
type: task
priority: normal
created_at: 2026-03-02T12:00:52Z
updated_at: 2026-03-02T12:02:28Z
---

Update function docs and user docs so fill_in/select/choose/check/uncheck/upload consistently show plain label string as the first example, with helper locator variants after.

## TODO
- [x] Update `Cerberus` function docs to show plain string/regex label shorthand first for `fill_in/select/choose/check/uncheck/upload`.
- [x] Update user-facing docs/examples (`README`, `getting-started`, `cheatsheet`) to use label-string examples first for these form actions.
- [x] Run `mix format` and `mix precommit`.
- [x] Add summary and complete bean.

## Summary of Changes
- Added/updated public function `@doc` text in `Cerberus` so form-field actions clearly present plain label string shorthand as the primary example.
- Switched form examples in README/getting-started to label string first.
- Updated cheatsheet core action examples to label-string first and added explicit check/uncheck/upload rows in the same style.
- Verified with formatting and full precommit checks.
