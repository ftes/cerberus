---
# cerberus-i8rx
title: Remove browser dialog APIs and handling
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:57:36Z
updated_at: 2026-03-09T18:59:29Z
---

## Goal

Remove Cerberus dialog assertions and browser dialog handling with a clean cut across code, tests, and docs.

## Todo

- [x] Remove public dialog APIs and option schema
- [x] Remove browser-driver dialog tracking and auto-handling
- [x] Remove dialog tests, fixtures, and docs references
- [x] Run format and targeted tests
- [x] Create follow-up bean for imperative low-level window/tab/dialog API plus sugar layer

## Summary of Changes

- Verified the codebase no longer exposes assert_dialog or browser dialog-handling internals; the remaining work was doc cleanup.
- Removed the last public dialog references from README and docs/architecture.md and docs/fixtures.md.
- Created follow-up feature bean cerberus-xzlh for an imperative browser window/tab/dialog primitive layer with sugar wrappers on top.
- Ran mix format and source .envrc && PORT=4127 mix test test/cerberus/documentation_examples_test.exs test/cerberus/browser_extensions_test.exs successfully.
