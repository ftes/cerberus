---
# cerberus-16my
title: Fold aria-label into Playwright-style locators
status: completed
type: feature
priority: normal
created_at: 2026-03-08T07:29:10Z
updated_at: 2026-03-08T07:49:17Z
---

## Context

Implement the locator/assertion API cut to broaden label and role name semantics, remove dedicated public aria-label APIs, and remove public `match_by` from assertion options.

## Todo

- [x] Update public locator and option types to remove dedicated aria-label and public match_by
- [x] Broaden form label matching and supported role name matching across drivers
- [x] Update docs and tests for the new API shape
- [x] Run format and targeted tests
- [x] Run precommit and browser-related coverage for the touched slice

## Summary of Changes

- Removed the public `aria_label(...)` helper, the `~l"..."a` sigil modifier, and public assertion `match_by` support.
- Kept assertions locator-first by leaving role, title, alt, placeholder, and testid assertions on locator engine paths instead of public `match_by` routing.
- Broadened field label matching to cover associated labels, wrapping labels, `aria-labelledby`, and `aria-label` across static, live, and browser drivers.
- Broadened role-name matching for supported roles to consider text plus `aria-labelledby` and `aria-label` in the browser, static HTML, and LiveView click resolution paths.
- Updated fixtures, docs, and tests to use label locators for form controls and role locators for accessible-name matching.
- Verified with targeted tests, `mix precommit`, full `mix test`, and `mix test --only slow` under `MIX_ENV=test`.
