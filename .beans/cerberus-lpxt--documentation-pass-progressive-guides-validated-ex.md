---
# cerberus-lpxt
title: 'Documentation pass: progressive guides + validated examples'
status: completed
type: task
priority: normal
created_at: 2026-02-28T06:48:05Z
updated_at: 2026-02-28T06:53:00Z
---

## Objective
Upgrade user-facing docs to high quality with a progressive learning path and verified examples.

## Scope
- Restructure README for reader-first flow (simple to advanced).
- Add ExDoc extras for getting started, cheatsheet, and architecture/flow guides.
- Add at least one mermaid diagram and useful admonition blocks where they aid clarity.
- Ensure code examples are executable by adding/updating tests that mirror documented flows.

## Work Breakdown
- [x] Audit current docs for gaps and redundancies.
- [x] Rewrite README into a progressive narrative with practical examples.
- [x] Add dedicated docs pages (getting started, cheatsheet, advanced patterns).
- [x] Add mermaid diagram(s) where architecture/flow is easier visually.
- [x] Add admonition blocks for pitfalls and best practices.
- [x] Add/update tests that validate documented examples.
- [x] Update ExDoc config so new docs are discoverable.
- [x] Run mix test + mix precommit.

## Acceptance Criteria
- [x] A new reader can start with one simple example and graduate to multi-driver usage.
- [x] Examples in docs are covered by executable tests and pass.
- [x] Docs render cleanly in ExDoc with meaningful structure.
- [x] Cheatsheet and architecture visual are present and useful.

## Summary of Changes
- Rewrote `README.md` into a user-first progression focused on the two public usage modes: `:auto` (default non-browser) and `:browser`.
- Added dedicated ExDoc guides: `docs/getting-started.md`, `docs/cheatsheet.md`, and `docs/architecture.md`.
- Added an architecture mermaid diagram and practical admonition blocks (`Tip`, `Info`, `Warning`) where they clarify behavior/pitfalls.
- Updated ExDoc configuration in `mix.exs` to include and group the new guides in navigation.
- Added `test/core/documentation_examples_test.exs` to execute the primary documented flows and verify examples stay working.
- Validated docs/examples with `mix test test/core/documentation_examples_test.exs` and full `mix precommit`.
