---
# cerberus-77sz
title: Inline fixture constants and remove Cerberus.Fixtures module
status: completed
type: task
priority: normal
created_at: 2026-02-27T12:42:17Z
updated_at: 2026-02-27T12:45:55Z
parent: cerberus-syh3
---

## Scope
Remove shared `Cerberus.Fixtures` constants module and inline fixture paths/text in tests and fixture app modules.

## Tasks
- [x] Replace all `Cerberus.Fixtures` constant/helper references with inline literals.
- [x] Update fixture controllers/liveviews/routes to use direct strings.
- [x] Update core tests to use direct literals.
- [x] Delete `test/support/fixtures.ex`.
- [x] Run focused and broad test runs.

## Done When
- [x] No `Cerberus.Fixtures` constants module exists.
- [x] No source files reference `Cerberus.Fixtures` constants helpers.
- [x] Changes compile and tests execute.

## Summary of Changes
Inlined all fixture text/path constants directly in fixture app modules and core tests, removed aliases/imports of `Cerberus.Fixtures`, and deleted `test/support/fixtures.ex`.

Validation:
- `mix test test/cerberus/harness_test.exs test/core/cross_driver_text_test.exs` passed.
- `mix test test/core test/cerberus/harness_test.exs` executed and still shows the pre-existing 5 browser owner-form submit/assert failures.
