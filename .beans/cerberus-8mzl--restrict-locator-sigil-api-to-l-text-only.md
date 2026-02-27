---
# cerberus-8mzl
title: Restrict locator sigil API to ~l text-only
status: completed
type: task
priority: normal
created_at: 2026-02-27T17:22:35Z
updated_at: 2026-02-27T17:24:06Z
parent: cerberus-ktki
---

Simplify sigil API based on product usage: support only ~l text locator sigil and remove ~t/~L regex paths.

## Scope
- Keep `~l"..."` as the only custom locator sigil.
- Treat sigil values as text-only (no regex modifiers).
- Remove regex sigil helpers/tests/docs from public API.

## Acceptance
- [x] `~l"..."` works with click/assert_has/refute_has.
- [x] `~t` and `~L` are no longer part of Cerberus API/docs.
- [x] tests/docs updated for text-only sigil guidance.

## Summary of Changes
- Reduced public sigil API in `Cerberus` to `sigil_l/2` only.
- Enforced text-only behavior for `~l` by rejecting modifiers with explicit `InvalidLocatorError`.
- Removed regex/custom sigil helpers from `Cerberus.Locator`.
- Updated locator and API tests to assert `~l` behavior and modifier rejection.
- Updated public examples/docs to use only text-based `~l` locators.
