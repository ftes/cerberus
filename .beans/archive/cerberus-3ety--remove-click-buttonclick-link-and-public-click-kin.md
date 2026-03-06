---
# cerberus-3ety
title: Remove click_button/click_link and public click kind option
status: completed
type: feature
priority: normal
created_at: 2026-03-04T20:35:17Z
updated_at: 2026-03-04T20:47:50Z
---

Simplify click API to locator-driven click only. Remove click_button/click_link wrappers, remove :kind from public click options, update docs/tests/migration task to use click + explicit locators.

## Progress
- Added migration task tests that assert click_link and click_button are rewritten to click.
- Extended committed fixture-project migration assertions to verify rewritten feature tests contain no click_link or click_button calls.
- Verified both slow fixture migration tests pass with include slow.

## Summary of Changes
- Removed public click aliases click_link and click_button from Cerberus API.
- Removed public kind from click options/types and moved click-kind routing to internal locator-driven inference.
- Updated static/live driver click behavior to use internal inferred kind metadata.
- Updated migration task canonicalization so migrated click_link/click_button calls become click.
- Updated Cerberus tests to use click locators instead of click_link/click_button.
- Extended migration task tests (including committed fixture-project coverage) to assert rewrite away from click_link/click_button.
