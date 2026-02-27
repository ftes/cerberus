---
# cerberus-wgv2
title: Split conformance suites into explicit static+browser and live+browser matrices
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T12:32:16Z
updated_at: 2026-02-27T12:40:45Z
parent: cerberus-syh3
---

## Scope
Refactor conformance tests to avoid static+live coupling. Use explicit module/test driver matrices so shared suites are either `[:static, :browser]` or `[:live, :browser]`.

## Tasks
- [x] Audit existing core conformance modules for `drivers: [:static, :live]` or `[:static, :live, :browser]`.
- [x] Convert static HTML/form/navigation parity tests to `[:static, :browser]`.
- [x] Convert LiveView event/navigation parity tests to `[:live, :browser]`.
- [ ] Remove low-value `Enum.each` cross-driver loops where Harness matrix is sufficient.
- [x] Keep driver-specific tests explicit (single-driver) when semantics differ.
- [ ] Run full test suite and verify green.

## Done When
- [x] No conformance module uses static+live shared matrix.
- [x] Browser remains present in conformance parity matrices.
- [x] Test intent is clear from module names/tags.

## Additional Request
- [x] Remove `Harness.run/run!` support for `drivers:` opts; use only `context[:drivers]` tags (or harness defaults).
- [x] Replace inline `drivers:` calls in core tests with `@tag/@moduletag drivers:` metadata.
