---
# cerberus-7htu
title: Split conformance tests into focused modules with module-level driver tags
status: completed
type: task
priority: normal
created_at: 2026-02-27T08:17:34Z
updated_at: 2026-02-27T08:19:01Z
parent: cerberus-syh3
---

## Scope
Replace the single broad conformance test module with focused behavior-specific modules.

## Goals
- Use `@moduletag drivers: ...` for each focused module.
- Keep each module narrow (navigation/assertion domains) so growth remains maintainable.
- Preserve existing scenario coverage while restructuring.

## Planned Modules (initial)
- static navigation
- live navigation
- cross-driver text/assertion behavior

## Tests
- [x] old broad module removed.
- [x] focused modules use `@moduletag` driver combinations.
- [x] existing scenarios are still covered under the new structure.

## Done When
- [x] conformance suite is organized by behavior domain, not by mixed scenarios in one file.

## Notes
- Runtime test execution could not be re-run in this environment because `mix` is not available in PATH.

## Summary of Changes
- Replaced the broad conformance module with three focused modules: cross-driver text behavior, static navigation behavior, and live/browser navigation behavior.
- Added module-level driver selection via `@moduletag drivers: ...` in each focused module.
- Preserved existing conformance scenarios and assertion expectations while improving suite organization for future expansion (e.g. forms).
