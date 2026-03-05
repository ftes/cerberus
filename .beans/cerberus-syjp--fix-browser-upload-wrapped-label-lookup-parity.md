---
# cerberus-syjp
title: Fix browser upload wrapped-label lookup parity
status: completed
type: bug
priority: normal
created_at: 2026-03-05T05:54:46Z
updated_at: 2026-03-05T05:56:29Z
---

Make browser upload locator resolution consistent with fill_in/select/check by supporting controls nested inside labels without for=. Add regression coverage.

## Todo
- [x] Update browser upload candidate label resolution to include wrapping label fallback
- [x] Add regression test covering upload by wrapped label without for attribute
- [x] Run targeted tests with source .envrc and random PORT

## Summary of Changes

- Updated browser upload candidate label resolution in lib/cerberus/driver/browser/action_helpers.ex to use the same label fallback as other form actions, including wrapped-label lookup when for is absent.
- Added a new locator parity fixture with a wrapped file input label and added a regression case that uploads via label("Inline Avatar").
- Ran targeted tests after sourcing env vars with random port: source .envrc && PORT=4173 mix test test/cerberus/locator_parity_test.exs:295 --include slow.
- Result: 1 test, 0 failures.
