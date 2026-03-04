---
# cerberus-zr4o
title: Fix migrate_phoenix_test rewriting unrelated select/submit calls
status: completed
type: bug
priority: normal
created_at: 2026-03-04T17:52:26Z
updated_at: 2026-03-04T17:57:54Z
---

Scope migration rewrites to PhoenixTest APIs so Ecto select/other submit calls are not rewritten into text: keyword args, and formatter does not crash in downstream projects like ev2.


## Todo

- [x] Reproduce migration crash in ../ev2
- [x] Identify rewrite rule causing unrelated `select`/`submit` rewrites
- [x] Scope import detection to migratable calls only
- [x] Stop coercing arbitrary AST nodes into `[text: ...]`
- [x] Add regression coverage
- [x] Re-run migration command in ev2 with local Cerberus build

## Summary of Changes

- Reproduced the failure in `ev2` with hex Cerberus: migration rewrote non-Phoenix calls (e.g. `select([pra], count(...))`, `Timecards.submit(tc, project)`), then crashed in formatter with `CaseClauseError`.
- Updated migration import detection (`module_needs_cerberus_import?/1`) to require actual canonicalizable local calls instead of matching function names alone.
- Updated `explicit_locator_ast/1` to avoid rewriting arbitrary dynamic AST nodes into `[text: ...]`; only known literal/regex forms are locatorized.
- Added regression test `write mode does not rewrite unrelated select/submit calls`.
- Verified migration tests pass and verified `MIX_ENV=test mix cerberus.migrate_phoenix_test` in `ev2` (with local path Cerberus) now completes dry-run without formatter crash.
