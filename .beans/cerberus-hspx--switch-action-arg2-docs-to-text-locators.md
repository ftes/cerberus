---
# cerberus-hspx
title: Switch action arg2 docs to text locators
status: completed
type: task
priority: normal
created_at: 2026-03-11T12:47:27Z
updated_at: 2026-03-11T12:49:18Z
---

Update public docs and examples so arg 2 for action functions uses text locators instead of label locators, while keeping select option examples as text locators.

- [x] find user-facing docs/examples that use label locators in action arg 2
- [x] update docs/examples to text locator forms for action arg 2 only
- [x] run focused verification for doc/example coverage and summarize changes

## Summary of Changes

Updated public action examples in README, guides, cheatsheet, migration docs, and the docs-backed example test so action arg 2 now uses default text sigils instead of label sigils. Left label locator reference material and non-action examples intact. Ran `mix format` on the touched files and verified with `source .envrc && PORT=4127 mix test test/cerberus/documentation_examples_test.exs`.
